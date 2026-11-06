/** Bounded local regression probe; never a production capacity claim. */
import assert from 'node:assert/strict';
import {randomUUID} from 'node:crypto';
import {cpus, platform, arch, totalmem} from 'node:os';
import {writeFile} from 'node:fs/promises';
import pg from 'pg';

const raw=process.env.DATABASE_URL ?? 'postgresql://postgres@127.0.0.1:55432/pop_nonaws_load';
const url=new URL(raw);
assert.equal(url.protocol,'postgresql:');
assert.equal(url.hostname,'127.0.0.1','Only loopback disposable database permitted');
assert.equal(url.port,'55432');
assert.equal(url.pathname,'/pop_nonaws_load','Never run against pop_demo or pop_test');
assert.equal(url.search,'','Connection options are forbidden');
process.env.DATABASE_URL=raw;
const adminUrl=new URL(raw);adminUrl.pathname='/postgres';
const admin=new pg.Client({connectionString:adminUrl.toString()});
await admin.connect();
try {if(!(await admin.query('SELECT 1 FROM pg_database WHERE datname=$1',['pop_nonaws_load'])).rowCount) await admin.query('CREATE DATABASE pop_nonaws_load');} finally {await admin.end();}
const {pool,migrate,seed,transaction,put}=await import('./db.js');
const {buildApp}=await import('./app.js');
const {hash}=await import('./domain.js');
const app=await buildApp({demoMode:true,accessCodeHash:hash('load-test-only'),allowReset:false,allowFaults:false,origins:[]});
let peakRss=process.memoryUsage().rss;
const memory=setInterval(()=>{peakRss=Math.max(peakRss,process.memoryUsage().rss);},20);
const samples:{phase:string;ms:number;responseBytes:number;requestBodyBytes:number}[]=[];
async function call(method:'GET'|'POST',path:string,session?:any,payload?:any,phase?:string) {
 const start=performance.now();const r=await app.inject({method,url:path,headers:session?{authorization:`Bearer ${session.token}`}:{},payload});
 if(phase)samples.push({phase,ms:performance.now()-start,responseBytes:Buffer.byteLength(r.body),requestBodyBytes:payload?Buffer.byteLength(JSON.stringify(payload)):0});
 assert.equal(r.statusCode,200,r.body);return r.json();
}
async function bounded(count:number,concurrency:number,fn:(i:number)=>Promise<any>) {let next=0;await Promise.all(Array.from({length:concurrency},async()=>{while(next<count)await fn(next++);}));}
try {
 assert.equal((await pool.query('SELECT current_database() AS name')).rows[0].name,'pop_nonaws_load');
 await migrate();
 // A previous run is disposable. Bound disk usage by removing only this database's datasets.
 await pool.query('TRUNCATE datasets CASCADE');
 const datasetId=await seed();
 const login=(actorCode:string)=>call('POST','/v1/demo/session',undefined,{actorCode,accessCode:'load-test-only'});
 const manager=await login('arun'),sakhi=await login('kavita');
 const snap=await call('GET','/v1/bootstrap',sakhi);
 const template=snap.members[0];
 await transaction(async c=>{for(let i=0;i<1000;i++)await put(c,'members',{...template,id:randomUUID(),datasetId,code:`load-${i}`,displayName:`Synthetic load member ${i}`,openingSavingsPaise:0});});
 const before=await call('GET','/v1/dashboard',manager);
 assert.equal(before.memberCount,1006);
 const started=performance.now();
 await bounded(100,8,i=>call('GET',i%2?'/v1/bootstrap':'/v1/dashboard',manager,undefined,'reads'));
 const operation={datasetId,operationId:randomUUID(),kind:'transaction.post',clientCreatedAt:new Date().toISOString(),payload:{transactionId:randomUUID(),memberId:snap.members.find((m:any)=>m.code==='rani').id,meetingId:snap.meetings[0].id,type:'savings_deposit',amountPaise:20000,businessDate:snap.businessDate}};
 const results:any[]=[];
 await bounded(20,8,async()=>results.push(await call('POST','/v1/mutations',sakhi,operation,'financialRetries')));
 assert.equal(results.filter(r=>!r.replayed).length,1);
 const after=await call('GET','/v1/dashboard',manager);
 assert.equal(after.savingsPaise,before.savingsPaise+20000);
 const records=await pool.query("SELECT count(*)::int AS count FROM records WHERE dataset_id=$1 AND entity_type='transactions' AND id=$2",[datasetId,operation.payload.transactionId]);
 assert.equal(records.rows[0].count,1);
 const summarize=(phase:string)=>{const rows=samples.filter(s=>s.phase===phase),ms=rows.map(r=>r.ms).sort((a,b)=>a-b);return {requests:rows.length,p50Ms:ms[Math.ceil(ms.length*.5)-1],p95Ms:ms[Math.ceil(ms.length*.95)-1],requestBodyBytes:rows.reduce((n,r)=>n+r.requestBodyBytes,0),responseBodyBytes:rows.reduce((n,r)=>n+r.responseBytes,0)};};
 const evidence={status:'PASS',recordedAt:new Date().toISOString(),database:'127.0.0.1:55432/pop_nonaws_load',workload:{syntheticMembers:1000,totalMembers:after.memberCount,concurrency:8,reads:100,retries:20,distinctFinancialEffects:1},elapsedMs:performance.now()-started,reads:summarize('reads'),financialRetries:summarize('financialRetries'),memory:{peakSampledNodeRssBytes:peakRss,final:process.memoryUsage()},machine:{platform:platform(),arch:arch(),cpu:cpus()[0]?.model,logicalCpus:cpus().length,totalMemoryBytes:totalmem()},caveat:'Local Fastify injection plus PostgreSQL; excludes network/TLS/browser and database-process memory. Shared-machine timing, bounded regression only, not production capacity. Bytes are JSON bodies, not wire bytes.'};
 const output=process.argv[2]??'docs/evidence/nonaws-load.json';await writeFile(output,JSON.stringify(evidence,null,2)+'\n');console.log(JSON.stringify(evidence,null,2));
} finally {clearInterval(memory);await app.close();await pool.end();}
