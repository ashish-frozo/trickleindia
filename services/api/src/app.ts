import Fastify from 'fastify';
import { simulate } from './simulation.js';
import cors from '@fastify/cors';
import rateLimit from '@fastify/rate-limit';
import { randomBytes, timingSafeEqual } from 'node:crypto';
import { readFile } from 'node:fs/promises';
import { z } from 'zod';
import { pool, transaction, snapshot, scope, assignments, active, seed, type Client } from './db.js';
import { DomainError, fail, hash, balances, effective, sum, entities, type Entity, type Row } from './domain.js';
import { authenticate, mutate, type Identity } from './mutations.js';

export type Config = { demoMode: boolean; accessCodeHash: string; allowReset: boolean; allowFaults: boolean; origins: string[] };
export async function buildApp(config: Config) {
  if(config.demoMode && !/^[a-f0-9]{64}$/.test(config.accessCodeHash)) throw new Error('DEMO_ACCESS_CODE_HASH must be a SHA-256 hex digest');
  const app=Fastify({logger:false,bodyLimit:32768,ajv:{customOptions:{removeAdditional:false}}});
  await app.register(cors,{origin:config.origins,methods:['GET','POST']});
  await app.register(rateLimit,{global:false});
  app.setErrorHandler((error,_req,reply)=>{
    const status=(error as any).statusCode;
    const unavailable=['ECONNREFUSED','ECONNRESET','08000','08003','08006','57P01'].includes((error as any).code);
    const e=error instanceof DomainError?error:unavailable?new DomainError('TEMPORARILY_UNAVAILABLE',503):new DomainError(status===429?'RATE_LIMITED':status===400||status===415?'INVALID_PAYLOAD':'INTERNAL_ERROR',status===429?429:status===400||status===415?status:500);
    reply.code(e.status).send({error:{code:e.code,messageKey:`error_${e.code}`,retryable:[429,503].includes(e.status),...e.details},requestId:_req.id});
  });
  app.setNotFoundHandler(()=>fail('NOT_FOUND',404));
  app.addHook('preSerialization',async(req,_reply,payload)=>payload && typeof payload==='object' && !Array.isArray(payload) ? {...payload,requestId:req.id}:payload);
  const tokenHash=(req: {headers:{authorization?:string}}) => {
    const token=req.headers.authorization?.match(/^Bearer ([A-Za-z0-9_-]{43})$/)?.[1];
    if(!token) fail('SESSION_EXPIRED',401);return hash(token);
  };
  const read=async<T>(req:any,work:(c:Client,identity:Identity)=>Promise<T>) => transaction(async c=>work(c,await authenticate(c,tokenHash(req))),'ISOLATION LEVEL REPEATABLE READ READ ONLY');
  const scoped=async(c:Client,i:Identity)=>scope(await snapshot(c,i.datasetId),i.actor,await assignments(c,i.datasetId,i.actor.id));
  const manager=(i:Identity)=>{if(i.actor.role!=='manager') fail('FORBIDDEN',403);};
  const demo=()=>{if(!config.demoMode) fail('NOT_FOUND',404);};
  const checkCode=(code:string)=>timingSafeEqual(Buffer.from(hash(code),'hex'),Buffer.from(config.accessCodeHash,'hex'));
  const parse=<T>(schema:z.ZodType<T>,data:unknown):T=>{const r=schema.safeParse(data);if(!r.success) fail('INVALID_PAYLOAD');return r.data;};
  const idFrom=(req:any)=>parse(z.uuid(),req.params.id);
  const pageSchema=z.object({offset:z.coerce.number().int().min(0).default(0),limit:z.coerce.number().int().min(1).max(500).default(100)});
  app.get('/healthz',async()=>({status:'ok'}));
  app.get('/readyz',async()=>transaction(async c=>{await active(c);const version=await c.query('SELECT version FROM migrations WHERE version=1');if(!version.rowCount)fail('TEMPORARILY_UNAVAILABLE',503);return {status:'ready'};}));
  app.post('/v1/demo/session',{config:{rateLimit:{max:10,timeWindow:'1 minute'}}},async req=>{
    demo();const input=parse(z.strictObject({actorCode:z.string().max(40),accessCode:z.string().max(200)}),req.body);
    if(!checkCode(input.accessCode)) fail('FORBIDDEN',403);
    return transaction(async c=>{
      const d=await active(c);
      const r=await c.query("SELECT body FROM records WHERE dataset_id=$1 AND entity_type='actors' AND body->>'code'=$2",[d.id,input.actorCode]);
      if(!r.rowCount) fail('FORBIDDEN',403);
      const token=randomBytes(32).toString('base64url'),expiresAt=new Date(Date.now()+8*3600000).toISOString();
      await c.query('INSERT INTO sessions VALUES($1,$2,$3,$4)',[hash(token),d.id,r.rows[0].body.id,expiresAt]);
      return {token,expiresAt,offlineUntil:expiresAt,actor:r.rows[0].body,datasetId:d.id};
    });
  });
  app.get('/v1/bootstrap',async req=>read(req,async(c,i)=>{
    const s=await scoped(c,i),clock=await c.query('SELECT cursor::text FROM sync_clock WHERE dataset_id=$1',[i.datasetId]);
    return {...s,datasetId:i.datasetId,cursor:clock.rows[0].cursor,serverTime:new Date().toISOString(),contentVersion:1,businessDate:'2026-11-05',demoFaultsEnabled:config.demoMode&&config.allowFaults};
  }));
  app.post('/v1/mutations',async(req,reply)=>{
    const i=await read(req,async(_c,i)=>i);
    if(config.demoMode && config.allowFaults && req.headers['x-demo-fault']==='temporary_failure') fail('TEMPORARILY_UNAVAILABLE',503);
    const result=await mutate(i,req.body);
    if(config.demoMode && config.allowFaults && req.headers['x-demo-fault']==='drop_after_commit') { reply.hijack();req.raw.socket.destroy();return; }
    return result;
  });
  app.get('/v1/operations/:id',async req=>read(req,async(c,i)=>{
    const q=parse(z.strictObject({datasetId:z.uuid()}),req.query);
    if(q.datasetId!==i.datasetId) fail('DATASET_MISMATCH',409);
    const r=await c.query('SELECT result FROM operation_receipts WHERE dataset_id=$1 AND actor_id=$2 AND operation_id=$3',[i.datasetId,i.actor.id,idFrom(req)]);
    if(!r.rowCount) fail('OPERATION_NOT_FOUND',404);
    // Re-filter receipts against current scope, including reassignment changes.
    const s=await scoped(c,i),result=r.rows[0].result;
    return {...result,records:result.records.filter((r:any)=>s[r.entityType as Entity].some(x=>x.id===r.record.id))};
  }));
  app.get('/v1/changes',async req=>read(req,async(c,i)=>{
    const q=parse(z.strictObject({datasetId:z.uuid(),after:z.string().regex(/^\d{1,19}$/),limit:z.coerce.number().int().min(1).max(500).default(100)}),req.query);
    if(q.datasetId!==i.datasetId) fail('DATASET_MISMATCH',409);
    const high=(await c.query('SELECT cursor::text FROM sync_clock WHERE dataset_id=$1',[i.datasetId])).rows[0].cursor;
    if(BigInt(q.after)>BigInt(high)) fail('INVALID_PAYLOAD');
    const events=(await c.query('SELECT cursor::text,records FROM change_events WHERE dataset_id=$1 AND cursor>$2 AND cursor<=$3 ORDER BY cursor LIMIT $4',[i.datasetId,q.after,high,q.limit])).rows;
    const s=await scoped(c,i);
    const records=events.flatMap(e=>e.records).filter((r:any)=>s[r.entityType as Entity].some(x=>x.id===r.record.id));
    const next=events.at(-1)?.cursor??high;
    return {datasetId:i.datasetId,records,nextCursor:next,highWaterCursor:high,hasMore:BigInt(next)<BigInt(high)};
  }));
  app.get('/v1/dashboard',async req=>read(req,async(c,i)=>{manager(i);const s=await scoped(c,i);return {...balances(s),datasetId:i.datasetId,asOf:new Date().toISOString()};}));
  app.get('/v1/groups',async req=>read(req,async(c,i)=>{
    const s=await scoped(c,i),b=balances(s);
    return {groups:s.groups.map(g=>({...g,memberCount:b.members.filter(m=>m.groupId===g.id).length,savingsPaise:sum(b.members.filter(m=>m.groupId===g.id),'savingsPaise')}))};
  }));
  app.get('/v1/members/:id/passbook',async req=>read(req,async(c,i)=>{
    const s=await scoped(c,i),id=idFrom(req),member=balances(s).members.find(m=>m.id===id);
    if(!member) fail('NOT_FOUND',404);
    return {member,transactions:s.transactions.filter(t=>t.memberId===id)};
  }));
  app.get('/v1/meetings/:id',async req=>read(req,async(c,i)=>{
    const s=await scoped(c,i),id=idFrom(req),meeting=s.meetings.find(m=>m.id===id);
    if(!meeting) fail('NOT_FOUND',404);
    return {meeting,attendance:s.attendance.filter(a=>a.meetingId===id),transactions:s.transactions.filter(t=>t.meetingId===id),cashReceivedPaise:sum(effective(s).filter(t=>t.meetingId===id),'amountPaise')};
  }));
  app.get('/v1/enterprises/:id',async req=>read(req,async(c,i)=>{
    const s=await scoped(c,i),id=idFrom(req),enterprise=balances(s).enterprises.find(e=>e.id===id);
    if(!enterprise) fail('NOT_FOUND',404);return {enterprise,transactions:s.transactions.filter(t=>t.enterpriseId===id)};
  }));
  app.get('/v1/support-requests',async req=>read(req,async(c,i)=>{
    const q=parse(pageSchema.extend({groupId:z.uuid().optional(),status:z.enum(['open','in_progress','resolved']).optional()}),req.query);
    const requests=(await scoped(c,i)).supportRequests.filter(r=>(!q.groupId||r.groupId===q.groupId)&&(!q.status||r.status===q.status));
    return {requests:requests.slice(q.offset,q.offset+q.limit),total:requests.length};
  }));
  app.get('/v1/support-requests/:id',async req=>read(req,async(c,i)=>{
    const request=(await scoped(c,i)).supportRequests.find(r=>r.id===idFrom(req));if(!request) fail('NOT_FOUND',404);
    const audit=(await c.query("SELECT body FROM audit_events WHERE dataset_id=$1 AND body->>'entityId'=$2 ORDER BY body->>'timestamp' LIMIT 100",[i.datasetId,request.id])).rows.map(r=>r.body);
    return {request,audit};
  }));
  app.get('/v1/audit-events',async req=>read(req,async(c,i)=>{
    manager(i);const q=parse(pageSchema,req.query);return {events:(await c.query("SELECT body FROM audit_events WHERE dataset_id=$1 ORDER BY body->>'timestamp' DESC,id LIMIT $2 OFFSET $3",[i.datasetId,q.limit,q.offset])).rows.map(r=>r.body)};
  }));
  app.get('/v1/content',async req=>read(req,async()=>JSON.parse(await readFile(new URL('../../../PoP_2_Demo_Coding_Pack/assets/content_cards.json',import.meta.url),'utf8'))));
  app.post('/v1/demo/whatsapp-events',async req=>{demo();const i=await read(req,async(_c,i)=>i);return simulate(i,req.body);});
  app.post('/v1/demo/reset',async req=>{
    demo();if(!config.allowReset) fail('FORBIDDEN',403);
    const p=parse(z.strictObject({accessCode:z.string().max(200),confirmation:z.literal('RESET DEMO')}),req.body);
    if(!checkCode(p.accessCode)) fail('FORBIDDEN',403);
    return transaction(async c=>{const i=await authenticate(c,tokenHash(req));manager(i);return {datasetId:await seed(c)};});
  });
  return app;
}
