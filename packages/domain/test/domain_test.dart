import 'dart:convert';
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pop_domain/pop_domain.dart';

class FailOnceStore extends MemoryStore {
  bool fail = true;
  @override
  Future<void> write(Json value) async {
    if (fail) {
      fail = false;
      throw StateError('simulated local commit failure');
    }
    await super.write(value);
  }
}

void main() {
  test(
    'decimal string parser preserves paise and rejects invalid boundaries',
    () {
      expect(parsePaise('200'), 20000);
      expect(parsePaise('0.01'), 1);
      expect(parsePaise('1000000.00'), 100000000);
      for (final value in [
        'NaN',
        '-1',
        '0',
        '0.001',
        '1000000.01',
        '1e2',
        '1,000',
      ]) {
        expect(() => parsePaise(value), throwsFormatException);
      }
    },
  );
  test('offline entry survives controller restart with same IDs and pending overlay', () async {
    final store = MemoryStore();
    final session = {
      'actor': {'id': 'actor', 'role': 'sakhi'},
      'token': 'token',
      'datasetId': 'dataset',
      'offlineUntil': DateTime.now()
          .add(const Duration(hours: 1))
          .toIso8601String(),
    };
    await store.setSession(session);
    await store.open('actor', 'dataset');
    final first = AppController(store, 'http://unused')..online = false;
    await first.init();
    first.data = {
      'members': [
        {'id': 'rani', 'openingSavingsPaise': 120000},
      ],
    };
    await first.enqueue('transaction.post', {
      'transactionId': 'tx',
      'memberId': 'rani',
      'type': 'savings_deposit',
      'amountPaise': 20000,
    }, intentId: 'intent');
    await first.enqueue('transaction.post', {
      'transactionId': 'tx',
      'memberId': 'rani',
      'type': 'savings_deposit',
      'amountPaise': 20000,
    }, intentId: 'intent');
    expect(first.queue.length, 1);
    expect(first.pending('rani', 'savings_deposit'), 20000);
    expect(first.savings(first.rows('members').single), 120000);
    first.dispose();
    final second = AppController(store, 'http://unused')..online = false;
    await second.init();
    expect(second.queue.single['operationId'], 'intent');
    expect(second.queue.single['payload']['transactionId'], 'tx');
    expect(second.pending('rani', 'savings_deposit'), 20000);
    second.dispose();
  });
  test('lost acknowledgment reconciles canonical origin and clears pending atomically', () async {
    final store = MemoryStore();
    await store.setSession({
      'actor': {'id': 'a', 'role': 'sakhi'},
      'token': 't',
      'datasetId': 'd',
      'offlineUntil': DateTime.now()
          .add(const Duration(hours: 1))
          .toIso8601String(),
    });
    await store.open('a', 'd');
    final controller = AppController(
      store,
      'http://api',
      client: MockClient(
        (request) async => http.Response(
          jsonEncode({
            'records': [
              {
                'entityType': 'transactions',
                'record': {
                  'id': 'tx',
                  'version': 1,
                  'originOperationId': 'op',
                  'memberId': 'm',
                  'type': 'savings_deposit',
                  'amountPaise': 20000,
                },
              },
            ],
            'nextCursor': '1',
            'hasMore': false,
          }),
          200,
        ),
      ),
    )..online = false;
    await controller.init();
    controller.data = {
      'members': [
        {'id': 'm', 'openingSavingsPaise': 120000},
      ],
    };
    await controller.enqueue('transaction.post', {
      'transactionId': 'tx',
      'memberId': 'm',
      'type': 'savings_deposit',
      'amountPaise': 20000,
    }, intentId: 'op');
    controller.online = true;
    await controller.pull();
    expect(controller.pending('m', 'savings_deposit'), 0);
    expect(controller.savings(controller.rows('members').single), 140000);
    expect((await store.read())!['cursor'], '1');
    controller.dispose();
  });
  test('never-dispatched attendance edits supersede; uncertain edits require reconciliation', () async {
    final store = MemoryStore();
    await store.setSession({
      'actor': {'id': 'a', 'role': 'sakhi'},
      'datasetId': 'd',
      'offlineUntil': DateTime.now()
          .add(const Duration(hours: 1))
          .toIso8601String(),
    });
    await store.open('a', 'd');
    final c = AppController(store, 'http://unused')..online = false;
    await c.init();
    final p = {
      'attendanceId': 'att',
      'memberId': 'm',
      'meetingId': 'meet',
      'expectedVersion': 1,
      'status': 'present',
    };
    await c.enqueue('meeting.attendance_set', p);
    await c.enqueue('meeting.attendance_set', {...p, 'status': 'absent'});
    expect(c.queue.first['state'], 'superseded');
    c.queue.last['hasEverDispatched'] = true;
    await expectLater(
      c.enqueue('meeting.attendance_set', p),
      throwsA(isA<ApiError>()),
    );
    c.dispose();
  });

  test('ambiguous discard reconciles accepted receipt and preserves financial effect', () async {
    final store = MemoryStore();
    await store.setSession({
      'actor': {'id': 'a', 'role': 'sakhi'},
      'token': 't',
      'datasetId': 'd',
      'offlineUntil': DateTime.now()
          .add(const Duration(hours: 1))
          .toIso8601String(),
    });
    await store.open('a', 'd');
    final c = AppController(
      store,
      'http://api',
      client: MockClient(
        (request) async => http.Response(
          jsonEncode({
            'records': [
              {
                'entityType': 'transactions',
                'record': {
                  'id': 'tx',
                  'version': 2,
                  'operationId': 'op',
                  'originOperationId': 'reversal',
                  'memberId': 'm',
                  'type': 'savings_deposit',
                  'amountPaise': 20000,
                  'reversedByTransactionId': 'rev',
                },
              },
            ],
          }),
          200,
        ),
      ),
    )..online = false;
    await c.init(autoSync: false);
    c.data = {
      'members': [
        {'id': 'm', 'openingSavingsPaise': 120000},
      ],
    };
    await c.enqueue('transaction.post', {
      'transactionId': 'tx',
      'memberId': 'm',
      'type': 'savings_deposit',
      'amountPaise': 20000,
    }, intentId: 'op');
    c.queue.single['hasEverDispatched'] = true;
    c.online = true;
    await c.discard(c.queue.single);
    expect(c.queue.single['state'], 'acknowledged');
    expect(c.pending('m', 'savings_deposit'), 0);
    expect(c.savings(c.rows('members').single), 120000);
    c.apply([
      {
        'entityType': 'transactions',
        'record': {
          'id': 'tx',
          'version': 1,
          'operationId': 'op',
          'memberId': 'm',
          'type': 'savings_deposit',
          'amountPaise': 20000,
        },
      },
    ]);
    expect(c.savings(c.rows('members').single), 120000);
    c.dispose();
  });

  test(
    'failed local commit never becomes a successful duplicate-tap result',
    () async {
      final store = FailOnceStore();
      await store.setSession({
        'actor': {'id': 'a', 'role': 'sakhi'},
        'datasetId': 'd',
        'offlineUntil': DateTime.now()
            .add(const Duration(hours: 1))
            .toIso8601String(),
      });
      await store.open('a', 'd');
      final c = AppController(store, 'http://unused')..online = false;
      await c.init(autoSync: false);
      c.data = {
        'members': [
          {'id': 'm', 'openingSavingsPaise': 120000},
        ],
      };
      final payload = {
        'transactionId': 'tx',
        'memberId': 'm',
        'type': 'savings_deposit',
        'amountPaise': 20000,
      };
      await expectLater(
        c.enqueue('transaction.post', payload, intentId: 'intent'),
        throwsStateError,
      );
      expect(c.queue, isEmpty);
      await c.enqueue('transaction.post', payload, intentId: 'intent');
      expect(c.queue.length, 1);
      expect((await store.read())!['queue'].length, 1);
      expect(c.pending('m', 'savings_deposit'), 20000);
      c.dispose();
    },
  );

  test(
    'retry backoff honors server Retry-After while unrelated entries continue',
    () async {
      final store = MemoryStore();
      await store.setSession({
        'actor': {'id': 'a', 'role': 'sakhi'},
        'token': 't',
        'datasetId': 'd',
        'offlineUntil': DateTime.now()
            .add(const Duration(hours: 1))
            .toIso8601String(),
      });
      await store.open('a', 'd');
      var failures = 0;
      final c = AppController(
        store,
        'http://api',
        client: MockClient((request) async {
          if (request.method == 'GET') {
            return http.Response(
              jsonEncode({'records': [], 'nextCursor': '0', 'hasMore': false}),
              200,
            );
          }
          final envelope = jsonDecode(request.body) as Json;
          if (envelope['operationId'] == 'retry' && failures++ == 0) {
            return http.Response(
              jsonEncode({
                'error': {'code': 'RATE_LIMITED', 'retryable': true},
              }),
              429,
              headers: {'retry-after': '30'},
            );
          }
          final p = envelope['payload'];
          return http.Response(
            jsonEncode({
              'records': [
                {
                  'entityType': 'transactions',
                  'record': {
                    'id': p['transactionId'],
                    'version': 1,
                    'operationId': envelope['operationId'],
                    'memberId': 'm',
                    'type': 'savings_deposit',
                    'amountPaise': p['amountPaise'],
                  },
                },
              ],
            }),
            200,
          );
        }),
      )..online = false;
      await c.init(autoSync: false);
      c.data = {
        'members': [
          {'id': 'm', 'openingSavingsPaise': 120000},
        ],
      };
      await c.enqueue('transaction.post', {
        'transactionId': 'one',
        'memberId': 'm',
        'type': 'savings_deposit',
        'amountPaise': 10000,
      }, intentId: 'retry');
      await c.enqueue('transaction.post', {
        'transactionId': 'two',
        'memberId': 'm',
        'type': 'savings_deposit',
        'amountPaise': 20000,
      }, intentId: 'independent');
      c.online = true;
      await c.sync(force: true);
      expect(c.queue.first['state'], 'retry_wait');
      expect(c.queue.last['state'], 'acknowledged');
      expect(
        DateTime.parse(c.queue.first['nextAttemptAt'])
            .difference(DateTime.now())
            .inSeconds,
        greaterThanOrEqualTo(29),
      );
      expect(c.savings(c.rows('members').single), 140000);
      expect(c.pending('m', 'savings_deposit'), 10000);
      await c.sync(force: true);
      expect(c.pending('m', 'savings_deposit'), 10000);
      c.queue.first['nextAttemptAt'] = DateTime.now()
          .subtract(const Duration(seconds: 1))
          .toIso8601String();
      await c.sync(force: true);
      expect(c.pending('m', 'savings_deposit'), 0);
      expect(c.savings(c.rows('members').single), 150000);
      c.dispose();
    },
  );

  test('missing receipt does not discard an ambiguously dispatched financial intent', () async {
    final store = MemoryStore();
    await store.setSession({
      'actor': {'id': 'a', 'role': 'sakhi'},
      'token': 't',
      'datasetId': 'd',
      'offlineUntil': DateTime.now()
          .add(const Duration(hours: 1))
          .toIso8601String(),
    });
    await store.open('a', 'd');
    final c = AppController(
      store,
      'http://api',
      client: MockClient(
        (request) async => http.Response(
          jsonEncode({
            'error': {'code': 'OPERATION_NOT_FOUND', 'retryable': false},
          }),
          404,
        ),
      ),
    )..online = false;
    await c.init(autoSync: false);
    c.data = {
      'members': [
        {'id': 'm', 'openingSavingsPaise': 120000},
      ],
    };
    await c.enqueue('transaction.post', {
      'transactionId': 'tx',
      'memberId': 'm',
      'type': 'savings_deposit',
      'amountPaise': 20000,
    }, intentId: 'op');
    c.queue.single['hasEverDispatched'] = true;
    c.online = true;
    await expectLater(c.discard(c.queue.single), throwsA(isA<ApiError>()));
    expect(c.queue.single['state'], 'pending');
    expect(c.pending('m', 'savings_deposit'), 20000);
    c.dispose();
  });

  test('lease expiry, server revocation and actor or dataset switch retain private pending intent', () async {
    final store = MemoryStore();
    Json next = {
      'actor': {'id': 'sakhi', 'role': 'sakhi'},
      'datasetId': 'old',
      'token': 'old-token',
      'offlineUntil': DateTime.now()
          .add(const Duration(hours: 1))
          .toIso8601String(),
    };
    await store.setSession(Map<String, dynamic>.from(next));
    await store.open('sakhi', 'old');
    bool revoked = false;
    var calls = 0;
    final c = AppController(
      store,
      'http://api',
      client: MockClient((request) async {
        calls++;
        if (request.url.path == '/v1/demo/session') {
          return http.Response(jsonEncode(next), 200);
        }
        if (revoked) {
          return http.Response(
            jsonEncode({
              'error': {'code': 'SESSION_EXPIRED'},
            }),
            401,
          );
        }
        return http.Response(
          jsonEncode({
            'cursor': '0',
            'members': [
              {'id': 'm', 'openingSavingsPaise': 120000},
            ],
            'transactions': [],
          }),
          200,
        );
      }),
    )..online = false;
    await c.init(autoSync: false);
    c.data = {
      'members': [
        {'id': 'm', 'openingSavingsPaise': 120000},
      ],
    };
    await c.enqueue('transaction.post', {
      'transactionId': 'tx',
      'memberId': 'm',
      'type': 'savings_deposit',
      'amountPaise': 20000,
    }, intentId: 'private-intent');
    c.identity!['offlineUntil'] = DateTime.now()
        .subtract(const Duration(seconds: 1))
        .toIso8601String();
    await c.sync(force: true);
    expect(c.valid, false);
    expect(calls, 0);
    c.online = true;
    next = {
      ...next,
      'token': 'renewed',
      'offlineUntil': DateTime.now()
          .add(const Duration(hours: 1))
          .toIso8601String(),
    };
    await c.login('kavita', 'test-access');
    expect(c.valid, true);
    expect(c.queue.single['operationId'], 'private-intent');
    revoked = true;
    await expectLater(
      c.request('GET', '/v1/bootstrap'),
      throwsA(isA<ApiError>()),
    );
    expect(
      c.valid,
      false,
      reason: 'Known server revocation must lock cached records immediately',
    );
    expect(
      DateTime.parse((await store.session())!['offlineUntil'])
          .isBefore(DateTime.now()),
      true,
    );
    revoked = false;
    await c.login('kavita', 'test-access');
    next = {
      ...next,
      'actor': {'id': 'other', 'role': 'participant'},
    };
    await expectLater(
      c.login('rani-user', 'test-access'),
      throwsA(
        isA<ApiError>().having((e) => e.code, 'code', 'PENDING_ACTOR_SWITCH'),
      ),
    );
    expect(c.actor['id'], 'sakhi');
    next = {
      ...next,
      'actor': {'id': 'sakhi', 'role': 'sakhi'},
      'datasetId': 'reset-dataset',
    };
    await expectLater(
      c.login('kavita', 'test-access'),
      throwsA(
        isA<ApiError>().having((e) => e.code, 'code', 'PENDING_ACTOR_SWITCH'),
      ),
    );
    expect(c.identity!['datasetId'], 'old');
    expect(c.queue.single['operationId'], 'private-intent');
    c.dispose();
  });

  test(
    'reentrant sync triggers share one upload and preserve the frozen intent',
    () async {
      final store = MemoryStore();
      await store.setSession({
        'actor': {'id': 'a', 'role': 'sakhi'},
        'token': 't',
        'datasetId': 'd',
        'offlineUntil': DateTime.now()
            .add(const Duration(hours: 1))
            .toIso8601String(),
      });
      await store.open('a', 'd');
      final entered = Completer<void>(), release = Completer<void>();
      var posts = 0;
      final c = AppController(
        store,
        'http://api',
        client: MockClient((request) async {
          if (request.method == 'GET') {
            return http.Response(
              jsonEncode({'records': [], 'nextCursor': '1', 'hasMore': false}),
              200,
            );
          }
          posts++;
          entered.complete();
          await release.future;
          final op = jsonDecode(request.body) as Json;
          return http.Response(
            jsonEncode({
              'records': [
                {
                  'entityType': 'transactions',
                  'record': {
                    'id': op['payload']['transactionId'],
                    'version': 1,
                    'operationId': op['operationId'],
                    'memberId': 'm',
                    'type': 'savings_deposit',
                    'amountPaise': 20000,
                  },
                },
              ],
            }),
            200,
          );
        }),
      )..online = false;
      await c.init(autoSync: false);
      c.data = {
        'members': [
          {'id': 'm', 'openingSavingsPaise': 120000},
        ],
      };
      await c.enqueue('transaction.post', {
        'transactionId': 'tx',
        'memberId': 'm',
        'type': 'savings_deposit',
        'amountPaise': 20000,
      }, intentId: 'intent');
      final frozen = jsonEncode(c.envelope(c.queue.single));
      c.online = true;
      final first = c.sync(force: true);
      await entered.future;
      await Future.wait([c.sync(force: true), c.sync(), c.sync(force: true)]);
      expect(posts, 1);
      release.complete();
      await first;
      expect(c.pending('m', 'savings_deposit'), 0);
      expect(c.savings(c.rows('members').single), 140000);
      expect(jsonEncode(c.envelope(c.queue.single)), frozen);
      c.dispose();
    },
  );
  test(
    'unfinished form drafts survive reopening and clear on explicit reset',
    () async {
      final store = MemoryStore();
      await store.setSession({
        'actor': {'id': 'a', 'role': 'sakhi'},
        'datasetId': 'd',
        'token': 't',
        'offlineUntil': DateTime.now()
            .add(const Duration(hours: 1))
            .toIso8601String(),
      });
      final c = AppController(store, 'http://unused')..online = false;
      await c.init(autoSync: false);
      await c.saveFormDraft('entry/m', {
        'amount': '200.50',
        'intentId': 'stable',
      });
      c.dispose();
      final reopened = AppController(store, 'http://unused')..online = false;
      await reopened.init(autoSync: false);
      expect(reopened.formDrafts['entry/m']['amount'], '200.50');
      expect(reopened.queue, isEmpty);
      await reopened.saveFormDraft('entry/m', null);
      expect((await store.read())!['formDrafts'], isEmpty);
      await reopened.saveFormDraft('profile/new', {
        'displayName': 'Private draft',
      });
      await reopened.resetLocal();
      expect(reopened.formDrafts, isEmpty);
      expect((await store.read())!['formDrafts'], isEmpty);
      reopened.dispose();
    },
  );
  test(
    'invalid content never replaces last validated offline instructions',
    () async {
      final store = MemoryStore();
      await store.setSession({
        'actor': {'id': 'a', 'role': 'sakhi'},
        'datasetId': 'd',
        'token': 't',
        'offlineUntil': DateTime.now()
            .add(const Duration(hours: 1))
            .toIso8601String(),
      });
      final c = AppController(
        store,
        'http://unused',
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'schemaVersion': 1,
              'contentVersion': 'bad',
              'cards': [
                {'id': 'missing-translations'},
              ],
            }),
            200,
          ),
        ),
      );
      await c.init(autoSync: false);
      c.contentPack = {'contentVersion': 'last-good'};
      await expectLater(c.updateContent(), throwsFormatException);
      expect(c.contentPack!['contentVersion'], 'last-good');
      c.dispose();
    },
  );
}
