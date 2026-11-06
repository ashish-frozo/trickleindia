import {test} from 'node:test';
import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
import pg from 'pg';

const script = fileURLToPath(new URL('./guard-test-database.mjs', import.meta.url));
function guard(value) {
  const env = {...process.env};
  delete env.DATABASE_URL;
  if (value !== undefined) env.DATABASE_URL = value;
  return spawnSync(process.execPath, [script], {env, encoding:'utf8'}).status;
}
test('accepts explicit loopback disposable database URLs', () => {
  for (const host of ['127.0.0.1', 'localhost', '[::1]']) {
    assert.equal(guard(`postgresql://u:p@${host}:5432/pop_test`), 0);
  }
});
test('rejects missing, malformed, nonlocal and nondisposable databases', () => {
  for (const value of [undefined, '', 'invalid', 'https://localhost/pop_test',
    'postgresql://remote.example/pop_test', 'postgresql://localhost/pop_demo',
    'postgresql://localhost/pop_test#fragment']) {
    assert.notEqual(guard(value), 0);
  }
});
test('rejects pg connection options that override the checked host', () => {
  const value = 'postgresql://u:p@127.0.0.1:5432/pop_test?host=remote.example';
  // Parsing only: never connect to any database in this suite.
  assert.equal(new pg.Client({connectionString:value}).connectionParameters.host, 'remote.example');
  for (const query of ['host=remote.example', 'host=%2Ftmp', 'port=9999', 'sslmode=require']) {
    assert.notEqual(guard(`postgresql://u:p@127.0.0.1:5432/pop_test?${query}`), 0);
  }
});
