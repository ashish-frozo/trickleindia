import pg from 'pg';
import { readFile } from 'node:fs/promises';
import { randomUUID } from 'node:crypto';
import { entities, type Snapshot, type Row, type Entity, fail } from './domain.js';
pg.types.setTypeParser(1082, value => value);
export const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL, max: 12 });
export type Client = pg.PoolClient;
export async function transaction<T>(work: (c: Client) => Promise<T>, isolation = ''): Promise<T> {
  const c = await pool.connect();
  try { await c.query(`BEGIN ${isolation}`); const result = await work(c); await c.query('COMMIT'); return result; }
  catch (e) { await c.query('ROLLBACK'); throw e; } finally { c.release(); }
}
export async function migrate() {
  await transaction(async c => {
    await c.query('SELECT pg_advisory_xact_lock(4020261105)');
    const exists = await c.query("SELECT to_regclass('public.migrations') AS name");
    if (!exists.rows[0].name) await c.query(await readFile(new URL('../migrations/001_initial.sql', import.meta.url),'utf8'));
    for (const [version,file] of [[2,'002_visits.sql'],[3,'003_identity.sql'],[4,'004_content.sql']] as const) if (!(await c.query('SELECT version FROM migrations WHERE version=$1',[version])).rowCount) await c.query(await readFile(new URL('../migrations/'+file, import.meta.url),'utf8'));
  });
}
export async function active(c: Client) {
  const r = await c.query('SELECT * FROM datasets WHERE active');
  if (!r.rowCount) fail('TEMPORARILY_UNAVAILABLE',503);
  return r.rows[0];
}
export async function snapshot(c: Client, datasetId: string): Promise<Snapshot> {
  const s = Object.fromEntries(entities.map(e => [e, []])) as unknown as Snapshot;
  const r = await c.query('SELECT entity_type,body FROM records WHERE dataset_id=$1 ORDER BY id',[datasetId]);
  for (const row of r.rows) s[row.entity_type as Entity].push(row.body);
  return s;
}
export async function put(c: Client, entity: Entity, r: Row) {
  await c.query('INSERT INTO records(dataset_id,entity_type,id,body) VALUES($1,$2,$3,$4) ON CONFLICT(dataset_id,entity_type,id) DO UPDATE SET body=excluded.body',[r.datasetId,entity,r.id,r]);
}
export async function seed(c?: Client) {
  const run = async (db: Client) => {
    await db.query('SELECT pg_advisory_xact_lock(4020261105)');
    const old = await db.query('SELECT id FROM datasets WHERE active FOR UPDATE');
    if (old.rowCount) await db.query('SELECT cursor FROM sync_clock WHERE dataset_id=$1 FOR UPDATE',[old.rows[0].id]);
    await db.query('UPDATE datasets SET active=false WHERE active');
    await db.query('DELETE FROM sessions');
    const fixture = JSON.parse(await readFile(new URL('../../../PoP_2_Demo_Coding_Pack/assets/demo_seed.json',import.meta.url),'utf8'));
    const id = randomUUID();
    await db.query('INSERT INTO datasets(id,business_date,schema_version) VALUES($1,$2,1)',[id,fixture.businessDate]);
    await db.query('INSERT INTO sync_clock(dataset_id) VALUES($1)',[id]);
    for (const entity of entities) for (const r of fixture[entity] ?? []) await put(db,entity,{...r,datasetId:id});
    for (const a of fixture.actorGroups) await db.query('INSERT INTO actor_groups VALUES($1,$2,$3)',[id,a.actorId,a.groupId]);
    return id;
  };
  return c ? run(c) : transaction(run);
}
export async function assignments(c: Client, datasetId: string, actorId: string): Promise<string[]> {
  return (await c.query('SELECT group_id FROM actor_groups WHERE dataset_id=$1 AND actor_id=$2',[datasetId,actorId])).rows.map(r => r.group_id);
}
export function scope(s: Snapshot, actor: Row, groups: string[]): Snapshot {
  if (actor.role === 'manager') return s;
  const memberIds = new Set(s.members.filter(m => actor.role === 'participant' ? m.id === actor.memberId : groups.includes(m.groupId)).map(m => m.id));
  const groupIds = new Set(actor.role==='sakhi' ? groups : s.members.filter(m => memberIds.has(m.id)).map(m => m.groupId));
  return { sakhiVisits: actor.role==='participant'?[]:s.sakhiVisits.filter(v=>groups.includes(v.groupId)&&v.sakhiId===actor.id), actors:s.actors.filter(a => a.id===actor.id || (a.role==='sakhi' && s.supportRequests.some(r=>memberIds.has(r.memberId) && r.assignedActorId===a.id))), groups:s.groups.filter(g=>groupIds.has(g.id)), members:s.members.filter(m=>memberIds.has(m.id)), loans:s.loans.filter(r=>memberIds.has(r.memberId)), enterprises:s.enterprises.filter(r=>memberIds.has(r.memberId)), meetings:s.meetings.filter(r=>groupIds.has(r.groupId)), attendance:s.attendance.filter(r=>memberIds.has(r.memberId)), transactions:s.transactions.filter(r=>memberIds.has(r.memberId)), supportRequests:s.supportRequests.filter(r=>memberIds.has(r.memberId) && (actor.role==='participant' || r.assignedActorId===actor.id)) };
}
