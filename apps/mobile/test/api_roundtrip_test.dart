import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:pop_domain/pop_domain.dart';
import 'package:pop_mobile/store.dart';

class NativeTestStore extends MemoryStore {
  final Directory directory;
  LocalDatabase? db;
  NativeTestStore(this.directory);
  @override
  Future<void> open(String actor, String dataset) async {
    await close();
    db = LocalDatabase(
      File('${directory.path}/$actor-$dataset.sqlite'),
      'b' * 64,
    );
  }

  @override
  Future<Json?> read() async {
    final row = await db!
        .customSelect('SELECT value FROM client_state WHERE id=1')
        .getSingleOrNull();
    return row == null ? null : jsonDecode(row.read<String>('value')) as Json;
  }

  @override
  Future<void> write(Json value) => db!.transaction(
    () => db!.customStatement(
      'INSERT INTO client_state VALUES(1,?) ON CONFLICT(id) DO UPDATE SET value=excluded.value',
      [jsonEncode(value)],
    ),
  );
  @override
  Future<void> close() async {
    await db?.close();
    db = null;
  }
}

void main() {
  test('real API + native encrypted outbox survives restart and lost acknowledgment', () async {
    HttpOverrides.global = null;
    final code = File(
      const String.fromEnvironment(
        'ACCESS_CODE_FILE',
        defaultValue: '../../.local/demo-access-code',
      ),
    ).readAsStringSync();
    const api = String.fromEnvironment(
      'API_URL',
      defaultValue: 'http://127.0.0.1:3000',
    );
    const expectDrop = bool.fromEnvironment('EXPECT_DROP', defaultValue: true);
    Future<Json> login(String actor) async {
      final r = await http.post(
        Uri.parse('$api/v1/demo/session'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({'actorCode': actor, 'accessCode': code}),
      );
      expect(r.statusCode, 200);
      return jsonDecode(r.body) as Json;
    }

    var manager = await login('arun');
    final reset = await http.post(
      Uri.parse('$api/v1/demo/reset'),
      headers: {
        'content-type': 'application/json',
        'authorization': 'Bearer ${manager['token']}',
      },
      body: jsonEncode({'accessCode': code, 'confirmation': 'RESET DEMO'}),
    );
    expect(reset.statusCode, 200);
    manager = await login('arun');
    final dir = Directory.systemTemp.createTempSync('pop-native-api-');
    final store = NativeTestStore(dir);
    final first = AppController(store, api);
    await first.init(autoSync: false);
    await first.login('kavita', code);
    first.online = false;
    final m = first.rows('members').firstWhere((m) => m['code'] == 'rani');
    final meeting = first.rows('meetings').single;
    final transactionId = const Uuid().v4(), operationId = const Uuid().v4();
    await first.enqueue('transaction.post', {
      'transactionId': transactionId,
      'memberId': m['id'],
      'meetingId': meeting['id'],
      'type': 'savings_deposit',
      'amountPaise': 20000,
      'businessDate': '2026-11-05',
    }, intentId: operationId);
    expect(first.savings(m), 120000);
    expect(first.pending(m['id'], 'savings_deposit'), 20000);
    first.dispose();
    await store.close();
    final second = AppController(store, api, allowFaults: true)..online = false;
    await second.init(autoSync: false);
    expect(second.queue.single['operationId'], operationId);
    expect(second.queue.single['payload']['transactionId'], transactionId);
    expect(second.queue.single['payloadHash'], isA<String>());
    if (expectDrop) second.nextFault = 'drop_after_commit';
    second.online = true;
    await second.sync(force: true);
    expect(second.queue.single['state'], 'acknowledged');
    if (expectDrop) {
      expect(
        second.queue.single['lastAttemptError'],
        'TEMPORARILY_UNAVAILABLE',
      );
    }
    expect(
      second.savings(
        second.rows('members').firstWhere((m) => m['code'] == 'rani'),
      ),
      140000,
    );
    expect(second.pending(m['id'], 'savings_deposit'), 0);
    await second.sync(force: true);
    expect(
      second
          .rows('transactions')
          .where((t) => t['operationId'] == operationId)
          .length,
      1,
    );
    final dashboard = await http.get(
      Uri.parse('$api/v1/dashboard'),
      headers: {'authorization': 'Bearer ${manager['token']}'},
    );
    expect((jsonDecode(dashboard.body) as Json)['savingsPaise'], 500000);
    second.dispose();
    await store.close();
    final otherDir = Directory.systemTemp.createTempSync('pop-native-second-');
    final otherStore = NativeTestStore(otherDir);
    final third = AppController(otherStore, api);
    await third.init(autoSync: false);
    await third.login('kavita', code);
    expect(
      third.savings(
        third.rows('members').firstWhere((m) => m['code'] == 'rani'),
      ),
      140000,
    );
    third.dispose();
    await otherStore.close();
    dir.deleteSync(recursive: true);
    otherDir.deleteSync(recursive: true);
  });
}
