import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:uuid/uuid.dart';
export 'package:uuid/uuid.dart';

typedef Json = Map<String, dynamic>;
String canonicalJson(dynamic value) {
  if (value is List) return '[${value.map(canonicalJson).join(',')}]';
  if (value is Map) {
    final keys = value.keys.cast<String>().toList()..sort();
    return '{${keys.map((k) => '${jsonEncode(k)}:${canonicalJson(value[k])}').join(',')}}';
  }
  return jsonEncode(value);
}

String payloadHash(Json value) =>
    sha256.convert(utf8.encode(canonicalJson(value))).toString();
const entityNames = [
  'actors',
  'groups',
  'members',
  'loans',
  'enterprises',
  'meetings',
  'attendance',
  'transactions',
  'supportRequests',
];
int parsePaise(String input) {
  if (!RegExp(r'^\d{1,7}(\.\d{1,2})?$').hasMatch(input.trim())) {
    throw const FormatException('INVALID_AMOUNT');
  }
  final p = input.trim().split('.');
  final n =
      int.parse(p[0]) * 100 +
      (p.length == 2 ? int.parse(p[1].padRight(2, '0')) : 0);
  if (n < 1 || n > 100000000) throw const FormatException('INVALID_AMOUNT');
  return n;
}

abstract class Store {
  Future<Json?> session();
  Future<void> setSession(Json? value);
  Future<void> open(String actor, String dataset);
  Future<Json?> read();
  Future<void> write(Json value);
  Future<void> close();
}

class MemoryStore implements Store {
  Json? current;
  final Map<String, Json> states = {};
  String key = '';
  @override
  Future<Json?> session() async => current;
  @override
  Future<void> setSession(Json? value) async {
    current = value;
  }

  @override
  Future<void> open(String actor, String dataset) async {
    key = '$actor/$dataset';
  }

  @override
  Future<Json?> read() async => states[key];
  @override
  Future<void> write(Json value) async {
    states[key] = jsonDecode(jsonEncode(value)) as Json;
  }

  @override
  Future<void> close() async {}
}

class ApiError implements Exception {
  final String code;
  final int status;
  final Json details;
  ApiError(this.code, this.status, this.details);
  @override
  String toString() => code;
}

class AppController extends ChangeNotifier {
  final Store store;
  final String baseUrl;
  final bool portal;
  final bool allowFaults;
  String? nextFault;
  final http.Client client;
  Json? identity;
  Json data = {};
  List<Json> queue = [];
  String cursor = '0';
  String? error, lastContact;
  bool busy = false, syncing = false, online = true;
  Timer? timer;
  Timer? expiryTimer;
  Completer<void>? syncDone;
  Completer<void>? refreshDone;
  bool refreshing = false;
  bool saving = false;
  Future<void> localSaves = Future<void>.value();
  AppController(
    this.store,
    this.baseUrl, {
    this.portal = false,
    this.allowFaults = const bool.fromEnvironment('DEMO_FAULTS'),
    http.Client? client,
  }) : client = client ?? http.Client();
  bool get valid =>
      identity != null &&
      DateTime.parse(identity!['offlineUntil']).isAfter(DateTime.now());
  Json get actor => identity?['actor'] as Json? ?? {};
  List<Json> rows(String entity) => (data[entity] as List? ?? [])
      .map((r) => Map<String, dynamic>.from(r as Map))
      .toList();
  List<Json> get unresolved => queue
      .where(
        (o) => ![
          'acknowledged',
          'discarded',
          'superseded',
          'rejected',
        ].contains(o['state']),
      )
      .toList();
  List<Json> get effective => rows('transactions')
      .where(
        (t) => t['type'] != 'reversal' && t['reversedByTransactionId'] == null,
      )
      .toList();
  String? groupLastAcceptedAt(String groupId) {
    final memberIds = rows('members')
        .where((m) => m['groupId'] == groupId)
        .map((m) => m['id'])
        .toSet();
    final times =
        entityNames
            .expand(rows)
            .where(
              (r) =>
                  r['groupId'] == groupId || memberIds.contains(r['memberId']),
            )
            .map((r) => r['updatedAt'])
            .whereType<String>()
            .toList()
          ..sort();
    return times.lastOrNull;
  }

  String? get lastAcceptedAt {
    final times =
        entityNames
            .expand(rows)
            .map((r) => r['updatedAt'])
            .whereType<String>()
            .toList()
          ..sort();
    return times.lastOrNull;
  }

  int total(List<Json> records, String key) =>
      records.fold(0, (a, r) => a + (r[key] as int? ?? 0));
  int savings(Json m) =>
      (m['openingSavingsPaise'] as int) +
      total(
        effective
            .where(
              (t) => t['memberId'] == m['id'] && t['type'] == 'savings_deposit',
            )
            .toList(),
        'amountPaise',
      );
  int principal(Json m) =>
      total(
        rows('loans').where((l) => l['memberId'] == m['id']).toList(),
        'openingPrincipalPaise',
      ) -
      total(
        effective
            .where(
              (t) =>
                  t['memberId'] == m['id'] &&
                  t['type'] == 'loan_principal_repayment',
            )
            .toList(),
        'amountPaise',
      );
  int pending(String member, String type) => unresolved
      .where(
        (o) =>
            o['kind'] == 'transaction.post' &&
            o['payload']['memberId'] == member &&
            o['payload']['type'] == type,
      )
      .fold(0, (a, o) => a + (o['payload']['amountPaise'] as int));
  int enterpriseAmount(Json e, bool sales) =>
      (e[sales ? 'openingCashSalesPaise' : 'openingCashExpensesPaise'] as int) +
      total(
        effective
            .where(
              (t) =>
                  t['enterpriseId'] == e['id'] &&
                  t['type'] ==
                      (sales ? 'enterprise_sale' : 'enterprise_expense'),
            )
            .toList(),
        'amountPaise',
      );
  Future<dynamic> request(
    String method,
    String path, [
    Json? body,
    Map<String, String>? extra,
  ]) async {
    if (!online) throw ApiError('TEMPORARILY_UNAVAILABLE', 503, {});
    final requestToken = identity?['token'];
    final fault = allowFaults && method == 'POST' && path == '/v1/mutations'
        ? nextFault
        : null;
    if (fault != null) nextFault = null;
    final response = await client
        .send(
          http.Request(method, Uri.parse('$baseUrl$path'))
            ..headers.addAll({
              'content-type': 'application/json',
              'x-demo-fault': ?fault,
              if (identity != null)
                'authorization': 'Bearer ${identity!['token']}',
              ...?extra,
            })
            ..body = body == null ? '' : jsonEncode(body),
        )
        .timeout(const Duration(seconds: 12));
    final value = jsonDecode(
      await response.stream.bytesToString().timeout(
        const Duration(seconds: 12),
      ),
    );
    if (path != '/v1/demo/session' && requestToken != identity?['token']) {
      throw ApiError('SESSION_EXPIRED', 401, {});
    }
    if (response.statusCode >= 400) {
      if (response.statusCode == 401 &&
          path != '/v1/demo/session' &&
          identity != null) {
        identity = {
          ...identity!,
          'offlineUntil': DateTime.now()
              .subtract(const Duration(seconds: 1))
              .toUtc()
              .toIso8601String(),
        };
        await store.setSession(identity);
        scheduleExpiry();
        notifyListeners();
      }
      final details = Map<String, dynamic>.from(value['error']);
      final retryAfter = response.headers['retry-after'];
      if (retryAfter != null) {
        var seconds = int.tryParse(retryAfter);
        if (seconds == null) {
          try {
            seconds =
                ((parseHttpDate(retryAfter)
                                .difference(DateTime.now())
                                .inMilliseconds +
                            999) /
                        1000)
                    .floor();
          } catch (_) {}
        }
        if (seconds != null) {
          details['retryAfterSeconds'] = seconds.clamp(0, 3600);
        }
      }
      throw ApiError(value['error']['code'], response.statusCode, details);
    }
    return value;
  }

  Future<void> init({bool autoSync = true}) async {
    identity = await store.session();
    if (identity != null) {
      await store.open(actor['id'], identity!['datasetId']);
      final saved = await store.read();
      if (saved != null) {
        data = Map<String, dynamic>.from(saved['data']);
        queue = (saved['queue'] as List)
            .map((o) => Map<String, dynamic>.from(o))
            .toList();
        cursor = saved['cursor'];
        lastContact = saved['lastContact'];
        for (final o in queue) {
          if (o['state'] == 'sending') o['state'] = 'pending';
        }
      }
    }
    scheduleExpiry();
    notifyListeners();
    timer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (valid) {
        unawaited(sync());
      } else {
        notifyListeners();
      }
    });
    if (valid && autoSync) unawaited(sync());
  }

  Future<void> persist() => store.write(
    Map<String, dynamic>.from(
      jsonDecode(
        jsonEncode({
          'data': data,
          'queue': queue,
          'cursor': cursor,
          'lastContact': lastContact,
        }),
      ),
    ),
  );

  Future<void> login(String code, String accessCode) async {
    if (syncing || refreshing || saving || busy) {
      throw ApiError('RECONCILE_FIRST', 409, {});
    }
    busy = true;
    error = null;
    notifyListeners();
    try {
      final next = Map<String, dynamic>.from(
        await request('POST', '/v1/demo/session', {
          'actorCode': code,
          'accessCode': accessCode,
        }),
      );
      if (identity != null &&
          (next['actor']['id'] != actor['id'] ||
              next['datasetId'] != identity!['datasetId']) &&
          unresolved.isNotEmpty) {
        throw ApiError('PENDING_ACTOR_SWITCH', 409, {});
      }
      await store.close();
      identity = next;
      data = {};
      queue = [];
      cursor = '0';
      lastContact = null;
      await store.open(actor['id'], next['datasetId']);
      final saved = await store.read();
      if (saved != null) {
        data = Map<String, dynamic>.from(saved['data']);
        queue = (saved['queue'] as List)
            .map((o) => Map<String, dynamic>.from(o))
            .toList();
        cursor = saved['cursor'];
      }
      await store.setSession(identity);
      scheduleExpiry();
      await refresh();
    } catch (e) {
      error = e is ApiError ? e.code : 'TEMPORARILY_UNAVAILABLE';
      rethrow;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (refreshing) {
      await refreshDone?.future;
      return;
    }
    if (syncing) await syncDone?.future;
    if (!valid) throw ApiError('SESSION_EXPIRED', 401, {});
    refreshing = true;
    refreshDone = Completer<void>();
    try {
      final fresh = Map<String, dynamic>.from(
        await request('GET', '/v1/bootstrap'),
      );
      data = fresh;
      cursor = fresh['cursor'];
      reconcile();
      error = null;
      lastContact = DateTime.now().toUtc().toIso8601String();
      await persist();
    } catch (e) {
      error = e is ApiError ? e.code : 'TEMPORARILY_UNAVAILABLE';
      rethrow;
    } finally {
      refreshing = false;
      refreshDone?.complete();
      notifyListeners();
    }
  }

  void reconcile() {
    final origins = entityNames
        .expand((e) => rows(e))
        .expand((r) => [r['originOperationId'], r['operationId']])
        .whereType<String>()
        .toSet();
    for (final o in queue) {
      if (origins.contains(o['operationId'])) {
        if (o['error'] != null) o['lastAttemptError'] = o['error'];
        o['state'] = 'acknowledged';
        o.remove('error');
        o.remove('details');
        o.remove('nextAttemptAt');
      }
    }
  }

  void apply(List records) {
    for (final item in records) {
      final entity = item['entityType'] as String;
      final record = Map<String, dynamic>.from(item['record']);
      final list = rows(entity);
      final idx = list.indexWhere((r) => r['id'] == record['id']);
      if (idx < 0) {
        list.add(record);
      } else if ((list[idx]['version'] as int) < (record['version'] as int)) {
        list[idx] = record;
      }
      data[entity] = list;
    }
    reconcile();
  }

  Future<void> pull() async {
    bool more = true;
    while (more) {
      final page = await request(
        'GET',
        '/v1/changes?datasetId=${identity!['datasetId']}&after=$cursor',
      );
      apply(page['records']);
      cursor = page['nextCursor'];
      lastContact = DateTime.now().toUtc().toIso8601String();
      await persist();
      more = page['hasMore'];
    }
  }

  Future<void> enqueue(
    String kind,
    Json payload, {
    String? intentId,
    String? replacesOperationId,
  }) {
    final frozenPayload = Map<String, dynamic>.from(
      jsonDecode(jsonEncode(payload)),
    );
    final job = localSaves.then((_) async {
      saving = true;
      final before = queue
          .map((o) => Map<String, dynamic>.from(jsonDecode(jsonEncode(o))))
          .toList();
      try {
        await enqueueLocal(
          kind,
          frozenPayload,
          intentId: intentId,
          replacesOperationId: replacesOperationId,
        );
      } catch (_) {
        queue = before;
        reconcile();
        rethrow;
      } finally {
        saving = false;
      }
      unawaited(sync());
    });
    localSaves = job.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {},
    );
    return job;
  }

  Future<void> enqueueLocal(
    String kind,
    Json payload, {
    String? intentId,
    String? replacesOperationId,
  }) async {
    if (!valid) throw ApiError('SESSION_EXPIRED', 401, {});
    if (![
      'member.create',
      'member.update',
      'meeting.attendance_set',
      'transaction.post',
      'support.create',
    ].contains(kind)) {
      throw ApiError('ONLINE_ONLY', 409, {});
    }
    if (kind != 'support.create' && actor['role'] != 'sakhi') {
      throw ApiError('FORBIDDEN', 403, {});
    }
    if (kind == 'support.create' &&
        !rows('members').any((m) => m['id'] == payload['memberId'])) {
      throw ApiError('FORBIDDEN', 403, {});
    }
    if (kind == 'transaction.post') {
      if (actor['role'] != 'sakhi') throw ApiError('FORBIDDEN', 403, {});
      final m = rows('members')
          .where((m) => m['id'] == payload['memberId'])
          .firstOrNull;
      if (m == null) throw ApiError('NOT_FOUND', 404, {});
      final amount = payload['amountPaise'];
      if (amount is! int || amount < 1 || amount > 100000000) {
        throw ApiError('INVALID_AMOUNT', 400, {});
      }
      if (payload['type'] == 'loan_principal_repayment' &&
          amount >
              principal(m) - pending(m['id'], 'loan_principal_repayment')) {
        throw ApiError('LOAN_BALANCE_EXCEEDED', 409, {});
      }
    }
    final id = intentId ?? const Uuid().v4();
    if (queue.any((o) => o['operationId'] == id)) return;
    if (kind == 'meeting.attendance_set' || kind == 'member.update') {
      final field = kind == 'meeting.attendance_set'
          ? 'attendanceId'
          : 'memberId';
      for (final old in queue.where(
        (o) =>
            o['kind'] == kind &&
            o['payload'][field] == payload[field] &&
            ![
              'acknowledged',
              'superseded',
              'discarded',
              'rejected',
            ].contains(o['state']),
      )) {
        if (old['hasEverDispatched'] == true) {
          throw ApiError('RECONCILE_FIRST', 409, {});
        }
        old['state'] = 'superseded';
      }
    }
    final operation = <String, dynamic>{
      'datasetId': identity!['datasetId'],
      'operationId': id,
      'kind': kind,
      'clientCreatedAt': DateTime.now().toUtc().toIso8601String(),
      'payload': jsonDecode(jsonEncode(payload)),
      'actorId': actor['id'],
      'replacesOperationId': ?replacesOperationId,
      'subjectId':
          payload['memberId'] ??
          payload['meetingId'] ??
          payload['requestId'] ??
          payload['originalTransactionId'],
      'localSequence':
          queue.fold<int>(
            0,
            (n, o) => max(n, o['localSequence'] as int? ?? 0),
          ) +
          1,
      'state': 'pending',
      'hasEverDispatched': false,
      'attempts': 0,
    };
    operation['payloadHash'] = payloadHash(envelope(operation));
    if (replacesOperationId != null) {
      for (final previous in queue.where(
        (o) =>
            o['operationId'] == replacesOperationId &&
            ['rejected', 'conflict', 'discarded'].contains(o['state']),
      )) {
        previous['state'] = 'superseded';
      }
    }
    queue.add(operation);
    await persist();
    notifyListeners();
  }

  Json envelope(Json o) => {
    for (final key in [
      'datasetId',
      'operationId',
      'kind',
      'clientCreatedAt',
      'payload',
    ])
      key: o[key],
  };
  Future<void> sync({bool force = false}) async {
    if (refreshing) await refreshDone?.future;
    if (syncing || saving || busy || !valid || !online) return;
    syncing = true;
    syncDone = Completer<void>();
    notifyListeners();
    try {
      for (final o
          in queue
              .where(
                (o) => [
                  'pending',
                  'sending',
                  'retry_wait',
                  'blocked',
                ].contains(o['state']),
              )
              .toList()) {
        if ((!force || (o['details']?['retryAfterSeconds'] as int? ?? 0) > 0) &&
            o['nextAttemptAt'] != null &&
            DateTime.parse(o['nextAttemptAt']).isAfter(DateTime.now())) {
          continue;
        }
        if (o['error'] == 'DATASET_MISMATCH') continue;
        if (o['payloadHash'] != null &&
            o['payloadHash'] != payloadHash(envelope(o))) {
          o['state'] = 'rejected';
          o['error'] = 'OPERATION_ID_REUSED';
          await persist();
          continue;
        }
        o['state'] = 'sending';
        o['hasEverDispatched'] = true;
        await persist();
        try {
          final result = await request('POST', '/v1/mutations', envelope(o));
          apply(result['records']);
          o['state'] = 'acknowledged';
          o.remove('error');
          lastContact = DateTime.now().toUtc().toIso8601String();
          await persist();
        } catch (e) {
          final api = e is ApiError
              ? e
              : ApiError('TEMPORARILY_UNAVAILABLE', 503, {});
          o['error'] = api.code;
          o['details'] = api.details;
          final retryable =
              api.details['retryable'] as bool? ??
              (api.status >= 500 || api.status == 429);
          o['state'] = api.status == 401 || api.code == 'DATASET_MISMATCH'
              ? 'blocked'
              : api.code == 'VERSION_CONFLICT' ||
                    api.code == 'POSSIBLE_DUPLICATE'
              ? 'conflict'
              : retryable
              ? 'retry_wait'
              : 'rejected';
          o['attempts'] = (o['attempts'] as int) + 1;
          o['nextAttemptAt'] = DateTime.now()
              .add(
                Duration(
                  seconds: max(
                    api.details['retryAfterSeconds'] as int? ?? 0,
                    min(120, 1 << min(o['attempts'] as int, 6)) +
                        Random().nextInt(3),
                  ),
                ),
              )
              .toIso8601String();
          await persist();
          if (api.status == 401 || api.code == 'DATASET_MISMATCH') {
            error = api.code;
            break;
          }
        }
      }
      await pull();
      error = null;
    } catch (e) {
      error = e is ApiError ? e.code : 'TEMPORARILY_UNAVAILABLE';
    } finally {
      syncing = false;
      syncDone?.complete();
      notifyListeners();
      if (!saving &&
          valid &&
          online &&
          !['SESSION_EXPIRED', 'DATASET_MISMATCH'].contains(error) &&
          queue.any((o) => o['state'] == 'pending')) {
        scheduleMicrotask(() => unawaited(sync()));
      }
    }
  }

  Future<void> discard(Json o) async {
    if (syncing) await syncDone?.future;
    if (o['hasEverDispatched'] == true) {
      try {
        final receipt = await request(
          'GET',
          '/v1/operations/${o['operationId']}?datasetId=${o['datasetId']}',
        );
        apply(receipt['records']);
        o['state'] = 'acknowledged';
        await persist();
        notifyListeners();
        return;
      } on ApiError catch (e) {
        if (e.code != 'OPERATION_NOT_FOUND') rethrow;
        const definitive = [
          'INVALID_PAYLOAD',
          'INVALID_AMOUNT',
          'FORBIDDEN',
          'VERSION_CONFLICT',
          'POSSIBLE_DUPLICATE',
          'MEETING_CLOSED',
          'LOAN_BALANCE_EXCEEDED',
          'TRANSACTION_ID_REUSED',
          'ALREADY_REVERSED',
        ];
        if (!definitive.contains(o['error'])) {
          throw ApiError('RECONCILE_FIRST', 409, {});
        }
      }
    }
    o['state'] = 'discarded';
    await persist();
    notifyListeners();
  }

  Future<void> onlineMutation(String kind, Json payload) async {
    if (unresolved.isNotEmpty && kind == 'meeting.submit') {
      throw ApiError('SYNC_BEFORE_SUBMIT', 409, {});
    }
    final result = await request('POST', '/v1/mutations', {
      'datasetId': identity!['datasetId'],
      'operationId': const Uuid().v4(),
      'kind': kind,
      'clientCreatedAt': DateTime.now().toUtc().toIso8601String(),
      'payload': payload,
    });
    apply(result['records']);
    await persist();
    await refresh();
  }

  Future<void> resetLocal() async {
    await localSaves;
    if (syncing) await syncDone?.future;
    if (refreshing) await refreshDone?.future;
    expiryTimer?.cancel();
    for (final o in queue) {
      if (o['state'] != 'acknowledged') o['state'] = 'discarded';
    }
    await persist();
    expiryTimer?.cancel();
    await store.setSession(null);
    await store.close();
    identity = null;
    data = {};
    queue = [];
    cursor = '0';
    error = null;
    notifyListeners();
  }

  Future<void> logout() async {
    if (syncing || refreshing || saving || busy) {
      throw ApiError('RECONCILE_FIRST', 409, {});
    }
    if (unresolved.isNotEmpty) throw ApiError('PENDING_ACTOR_SWITCH', 409, {});
    expiryTimer?.cancel();
    await store.setSession(null);
    await store.close();
    identity = null;
    data = {};
    queue = [];
    notifyListeners();
  }

  void scheduleExpiry() {
    expiryTimer?.cancel();
    if (identity == null) return;
    final duration = DateTime.parse(identity!['offlineUntil'])
        .difference(DateTime.now());
    expiryTimer = Timer(
      duration.isNegative ? Duration.zero : duration,
      notifyListeners,
    );
  }

  @override
  void dispose() {
    expiryTimer?.cancel();
    timer?.cancel();
    client.close();
    super.dispose();
  }
}
