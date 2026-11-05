import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pop_domain/pop_domain.dart';

class LocalDatabase extends GeneratedDatabase {
  LocalDatabase(File file, String key)
    : super(
        NativeDatabase(
          file,
          setup: (db) {
            final cipher = db.select('PRAGMA cipher;');
            if (cipher.isEmpty) {
              throw StateError('Encrypted SQLite build unavailable');
            }
            db.execute("PRAGMA key = '$key'");
            db.execute('PRAGMA journal_mode=WAL');
            db.execute('PRAGMA synchronous=FULL');
          },
        ),
      );
  @override
  int get schemaVersion => 1;
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => [];
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [];
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await customStatement(
        'CREATE TABLE client_state (id INTEGER PRIMARY KEY CHECK(id=1), value TEXT NOT NULL)',
      );
    },
  );
}

class EncryptedStore implements Store {
  final secure = const FlutterSecureStorage();
  LocalDatabase? db;
  @override
  Future<Json?> session() async {
    final raw = await secure.read(key: 'pop-session');
    return raw == null ? null : jsonDecode(raw) as Json;
  }

  @override
  Future<void> setSession(Json? value) async {
    if (value == null) {
      await secure.delete(key: 'pop-session');
    } else {
      await secure.write(key: 'pop-session', value: jsonEncode(value));
    }
  }

  @override
  Future<void> open(String actor, String dataset) async {
    await close();
    final name = 'pop-$actor-$dataset';
    var key = await secure.read(key: 'key-$name');
    if (key == null) {
      key = List.generate(
        32,
        (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
      ).join();
      await secure.write(key: 'key-$name', value: key);
    }
    final dir = await getApplicationSupportDirectory();
    db = LocalDatabase(File('${dir.path}/$name.sqlite'), key);
    await db!.customSelect('SELECT count(*) AS n FROM client_state').get();
  }

  @override
  Future<Json?> read() async {
    final row = await db!
        .customSelect('SELECT value FROM client_state WHERE id=1')
        .getSingleOrNull();
    return row == null ? null : jsonDecode(row.read<String>('value')) as Json;
  }

  @override
  Future<void> write(Json value) async {
    await db!.transaction(
      () => db!.customStatement(
        'INSERT INTO client_state(id,value) VALUES(1,?) ON CONFLICT(id) DO UPDATE SET value=excluded.value',
        [jsonEncode(value)],
      ),
    );
  }

  @override
  Future<void> close() async {
    await db?.close();
    db = null;
  }
}
