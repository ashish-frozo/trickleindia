import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:pop_mobile/store.dart';

void main() {
  test('native encrypted Drift database survives reopen and rejects unkeyed readers', () async {
    final dir = Directory.systemTemp.createTempSync('pop-encryption-');
    final file = File('${dir.path}/test.sqlite');
    final key = 'a' * 64;
    final db = LocalDatabase(file, key);
    await db.customStatement('INSERT INTO client_state VALUES(1,?)', [
      'synthetic-durable-outbox',
    ]);
    await db.close();
    final raw = sqlite.sqlite3.open(file.path);
    expect(
      () => raw.select('SELECT * FROM client_state'),
      throwsA(isA<sqlite.SqliteException>()),
    );
    raw.close();
    final reopened = LocalDatabase(file, key);
    final row = await reopened
        .customSelect('SELECT value FROM client_state')
        .getSingle();
    expect(row.read<String>('value'), 'synthetic-durable-outbox');
    await reopened.close();
    dir.deleteSync(recursive: true);
  });
}
