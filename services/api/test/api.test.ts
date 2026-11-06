import { test, before, after, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import { buildApp } from '../src/app.js';
import { pool, migrate, seed, transaction } from '../src/db.js';
import { hash } from '../src/domain.js';
import { authenticate, mutate } from '../src/mutations.js';
const app=await buildApp({demoMode:true,accessCodeHash:hash('test-only-access'),allowReset:true,allowFaults:true,origins:[]});
let address=1;
let sakhi:any, manager:any, participant:any, snap:any;
const call=async(method:any,url:string,session?:any,payload?:any)=>app.inject({method,url,remoteAddress:`127.0.0.${address++}`,headers:session?{authorization:`Bearer ${session.token}`}:{},payload});
const login=async(actorCode:string)=>{const r=await call('POST','/v1/demo/session',undefined,{actorCode,accessCode:'test-only-access'});assert.equal(r.statusCode,200,r.body);return r.json();};
const op=(kind:string,payload:any)=>({datasetId:sakhi.datasetId,operationId:randomUUID(),kind,clientCreatedAt:new Date().toISOString(),payload});
const action=(type='savings_deposit',amountPaise=20000)=>op('transaction.post',{transactionId:randomUUID(),memberId:snap.members.find((m:any)=>m.code==='rani').id,meetingId:snap.meetings[0].id,type,amountPaise,businessDate:'2026-11-05',...(type==='loan_principal_repayment'?{loanId:snap.loans.find((l:any)=>l.code==='loan-rani').id}:{})});
const post=async(o:any,session=sakhi)=>call('POST','/v1/mutations',session,o);
const dashboard=async()=> (await call('GET','/v1/dashboard',manager)).json();
before(async()=>{await migrate();await app.ready();});
beforeEach(async()=>{await seed();sakhi=await login('kavita');manager=await login('arun');participant=await login('rani-user');snap=(await call('GET','/v1/bootstrap',sakhi)).json();});
after(async()=>{await app.close();await pool.end();});
test('A01 server seed arithmetic and real readiness',async()=>{assert.equal((await call('GET','/readyz')).statusCode,200);const d=await dashboard();assert.equal(d.memberCount,6);assert.equal(d.groupCount,2);assert.equal(d.savingsPaise,480000);assert.equal(d.principalPaise,500000);assert.equal(d.enterprises[0].cashSurplusPaise,120000);});
test('A02/A23 scoped snapshots and guessed IDs',async()=>{assert.equal(snap.groups.length,1);assert.equal(snap.members.length,4);const p=(await call('GET','/v1/bootstrap',participant)).json();assert.equal(p.members.length,1);const all=(await call('GET','/v1/bootstrap',manager)).json();const other=all.members.find((m:any)=>m.code==='sita');assert.equal((await call('GET',`/v1/members/${other.id}/passbook`,sakhi)).statusCode,404);assert.equal((await post(action(),participant)).statusCode,403);});
test('A05/A06/A07/A08 concurrent identical retries have one financial effect',async()=>{const o=action();const results=await Promise.all(Array.from({length:8},()=>post(o)));for(const r of results) assert.equal(r.statusCode,200,r.body);assert.equal(results.filter(r=>!r.json().replayed).length,1);assert.equal((await dashboard()).savingsPaise,500000);const changed=structuredClone(o);changed.payload.amountPaise=30000;assert.equal((await post(changed)).json().error.code,'OPERATION_ID_REUSED');const newOp={...o,operationId:randomUUID()};assert.equal((await post(newOp)).json().error.code,'TRANSACTION_ID_REUSED');});
test('A09 invisible pages advance the raw cursor',async()=>{const meena=snap.members.find((m:any)=>m.code==='meena');await post(op('member.update',{memberId:meena.id,expectedVersion:1,patch:{displayName:'Meena Updated'}}));const r=await call('GET',`/v1/changes?datasetId=${sakhi.datasetId}&after=0&limit=1`,participant);assert.equal(r.statusCode,200,r.body);assert.equal(r.json().records.length,0);assert.equal(r.json().nextCursor,'1');assert.equal(r.json().hasMore,false);});
test('A11 stale attendance returns canonical record',async()=>{const a=snap.attendance[0];const p={attendanceId:a.id,meetingId:a.meetingId,memberId:a.memberId,status:'present',expectedVersion:1};assert.equal((await post(op('meeting.attendance_set',p))).statusCode,200);const r=await post(op('meeting.attendance_set',{...p,status:'absent'}));assert.equal(r.json().error.code,'VERSION_CONFLICT');assert.equal(r.json().error.currentRecord.status,'present');});
test('A12 concurrent repayments cannot exceed principal',async()=>{const results=await Promise.all([post(action('loan_principal_repayment',150000)),post(action('loan_principal_repayment',150000))]);assert.deepEqual(results.map(r=>r.statusCode).sort(),[200,409]);assert.equal((await dashboard()).principalPaise,350000);});
test('A13 submitted meeting blocks subsequent posting',async()=>{await post(action());const a=snap.attendance[0];await post(op('meeting.attendance_set',{attendanceId:a.id,meetingId:a.meetingId,memberId:a.memberId,status:'present',expectedVersion:1}));const m=(await call('GET',`/v1/meetings/${a.meetingId}`,sakhi)).json().meeting;assert.equal((await post(op('meeting.submit',{meetingId:m.id,expectedVersion:m.version}))).statusCode,200);assert.equal((await post(action())).json().error.code,'MEETING_CLOSED');});
test('A14 expense reversal restores opening cash once',async()=>{const e=snap.enterprises[0];const o=op('transaction.post',{transactionId:randomUUID(),memberId:e.memberId,enterpriseId:e.id,type:'enterprise_expense',amountPaise:35000,category:'seeds',businessDate:'2026-11-05'});assert.equal((await post(o)).statusCode,200);assert.equal((await dashboard()).enterprises[0].cashSurplusPaise,85000);const rev=()=>op('transaction.reverse',{transactionId:randomUUID(),originalTransactionId:o.payload.transactionId,reason:'Demo correction'});assert.equal((await post(rev(),manager)).statusCode,200);assert.equal((await dashboard()).enterprises[0].cashSurplusPaise,120000);assert.equal((await post(rev(),manager)).json().error.code,'ALREADY_REVERSED');});
test('A15 registration has zero balances and duplicate review',async()=>{const p={memberId:randomUUID(),groupId:snap.groups[0].id,displayName:'Lata Kumari',preferredLanguage:'hi',livelihoodCategory:'tailoring'};assert.equal((await post(op('member.create',p))).statusCode,200);const d=await dashboard();assert.equal(d.memberCount,7);assert.equal(d.savingsPaise,480000);assert.equal((await post(op('member.create',{...p,memberId:randomUUID(),displayName:'  LATA   Kumari '}))).json().error.code,'POSSIBLE_DUPLICATE');});
test('A17 expired sessions reject reads and writes',async()=>{await pool.query('UPDATE sessions SET expires_at=now()-interval \'1 second\' WHERE token_hash=$1',[hash(sakhi.token)]);assert.equal((await call('GET','/v1/bootstrap',sakhi)).statusCode,401);assert.equal((await post(action())).statusCode,401);});
test('A18 reset changes dataset and revokes old sessions',async()=>{const old=sakhi.datasetId;const r=await call('POST','/v1/demo/reset',manager,{accessCode:'test-only-access',confirmation:'RESET DEMO'});assert.equal(r.statusCode,200,r.body);assert.notEqual(r.json().datasetId,old);assert.equal((await call('GET','/v1/bootstrap',sakhi)).statusCode,401);});
test('A25 money boundaries and unknown authority fields rejected',async()=>{for(const amount of [0,-1,0.5,100000001]) {const r=await post(action('savings_deposit',amount));assert.equal(r.statusCode,400,r.body);}const o=action();(o as any).role='manager';assert.equal((await post(o)).statusCode,400);assert.equal((await dashboard()).savingsPaise,480000);});
test('support state transitions and mandatory resolution',async()=>{const r=snap.supportRequests[0];assert.equal((await post(op('support.update',{requestId:r.id,expectedVersion:1,status:'resolved',resolutionNote:'done'}),manager)).statusCode,400);assert.equal((await post(op('support.update',{requestId:r.id,expectedVersion:1,status:'in_progress'}),manager)).statusCode,200);assert.equal((await post(op('support.update',{requestId:r.id,expectedVersion:2,status:'resolved',resolutionNote:'Explained the meeting screen'}),sakhi)).statusCode,200);assert.equal((await dashboard()).openSupportRequests,0);});
test('A10 controlled writer barrier preserves bootstrap and commit cursor order',async()=>{
  const identity=await transaction(c=>authenticate(c,hash(sakhi.token)));
  let release!:()=>void, locked!:()=>void;
  const hold=new Promise<void>(r=>release=r), entered=new Promise<void>(r=>locked=r);
  const writerA=mutate(identity,action(),{afterLock:async()=>{locked();await hold;}});
  await entered;
  try {
    const during=(await call('GET','/v1/bootstrap',sakhi)).json();
    assert.equal(during.cursor,'0');assert.equal(during.transactions.length,0);
    let bLocked=false;
    const writerB=mutate(identity,action(),{afterLock:async()=>{bLocked=true;}});
    let blocked=false;
    for(let n=0;n<100;n++) {
      const r=await pool.query("SELECT count(*)::integer AS n FROM pg_stat_activity WHERE datname=current_database() AND wait_event_type='Lock' AND query LIKE 'SELECT cursor FROM sync_clock%'");
      if(r.rows[0].n>0) {blocked=true;break;}
    }
    assert.equal(blocked,true,'writer B must be observed waiting on the clock lock');assert.equal(bLocked,false);
    release();const [a,b]=await Promise.all([writerA,writerB]);
    assert.equal(a.changeCursor,'1');assert.equal(b.changeCursor,'2');
    const after=(await call('GET','/v1/bootstrap',sakhi)).json();assert.equal(after.cursor,'2');assert.equal(after.transactions.length,2);
    const page=(await call('GET',`/v1/changes?datasetId=${sakhi.datasetId}&after=0&limit=1`,sakhi)).json();assert.equal(page.nextCursor,'1');assert.equal(page.hasMore,true);
  } finally {release();await writerA;}
});
test('A06 actual HTTP response loss after commit reconciles by receipt',async()=>{
  if(!app.server.listening) await app.listen({host:'127.0.0.1',port:0});
  const address=app.server.address();assert.ok(address && typeof address!=='string');
  const o=action();
  await assert.rejects(fetch(`http://127.0.0.1:${address.port}/v1/mutations`,{method:'POST',headers:{authorization:`Bearer ${sakhi.token}`,'content-type':'application/json','x-demo-fault':'drop_after_commit'},body:JSON.stringify(o)}));
  const receipt=await call('GET',`/v1/operations/${o.operationId}?datasetId=${o.datasetId}`,sakhi);assert.equal(receipt.statusCode,200,receipt.body);
  assert.equal((await post(o)).json().replayed,true);assert.equal((await dashboard()).savingsPaise,500000);
});
test('A16 simulated message deduplicates and support lifecycle returns to one open request',async()=>{const event={simulatedMessageId:randomUUID(),demoContactCode:'demo-contact-rani',topicCode:'expense_help'};const a=await call('POST','/v1/demo/whatsapp-events',manager,event);assert.equal(a.statusCode,200,a.body);const b=await call('POST','/v1/demo/whatsapp-events',manager,event);assert.equal(b.json().replayed,true);assert.equal(a.json().request.id,b.json().request.id);assert.equal((await dashboard()).openSupportRequests,2);const r=a.json().request;assert.equal(r.source,'whatsapp_simulation');await post(op('support.update',{requestId:r.id,expectedVersion:1,status:'in_progress'}),manager);await post(op('support.update',{requestId:r.id,expectedVersion:2,status:'resolved',resolutionNote:'Explained expense entry'}),manager);assert.equal((await dashboard()).openSupportRequests,1);assert.equal((await call('POST','/v1/demo/whatsapp-events',participant,event)).statusCode,403);});
test('A21 retryable fault leaves no receipt and same ID subsequently succeeds',async()=>{const o=action();const r=await app.inject({method:'POST',url:'/v1/mutations',headers:{authorization:`Bearer ${sakhi.token}`,'x-demo-fault':'temporary_failure'},payload:o});assert.equal(r.statusCode,503);assert.equal(r.json().error.retryable,true);assert.equal((await dashboard()).savingsPaise,480000);assert.equal((await post(o)).statusCode,200);assert.equal((await dashboard()).savingsPaise,500000);});
test('A23 wrong loan/member and enterprise/member relationships fail without ledger effects',async()=>{const a=action('loan_principal_repayment',10000);a.payload.loanId=snap.loans.find((l:any)=>l.code==='loan-meena').id;assert.equal((await post(a)).statusCode,400);const e=snap.enterprises[0];const wrong=snap.members.find((m:any)=>m.code==='meena');const expense=op('transaction.post',{transactionId:randomUUID(),memberId:wrong.id,enterpriseId:e.id,type:'enterprise_expense',amountPaise:35000,category:'seeds',businessDate:'2026-11-05'});assert.equal((await post(expense)).statusCode,400);const d=await dashboard();assert.equal(d.principalPaise,500000);assert.equal(d.enterprises[0].cashSurplusPaise,120000);});
test('demo endpoints are absent when demo mode is disabled',async()=>{const prod=await buildApp({demoMode:false,accessCodeHash:'',allowReset:false,allowFaults:false,origins:[]});try{const r=await prod.inject({method:'POST',url:'/v1/demo/session',payload:{actorCode:'arun',accessCode:'test-only-access'}});assert.equal(r.statusCode,404);}finally{await prod.close();}});
test('malformed JSON and unknown routes retain the structured error contract',async()=>{const r=await app.inject({method:'POST',url:'/v1/mutations',headers:{authorization:`Bearer ${sakhi.token}`,'content-type':'application/json'},payload:'{bad-json'});assert.equal(r.statusCode,400);assert.equal(r.json().error.code,'INVALID_PAYLOAD');assert.ok(r.json().requestId);const absent=await call('GET','/v1/unknown',sakhi);assert.equal(absent.statusCode,404);assert.equal(absent.json().error.code,'NOT_FOUND');});
test('all sequential financial checkpoints match the canonical fixture',async()=>{await post(action());await post(action('loan_principal_repayment',10000));const e=snap.enterprises[0],expense=op('transaction.post',{transactionId:randomUUID(),memberId:e.memberId,enterpriseId:e.id,type:'enterprise_expense',amountPaise:35000,category:'seeds',businessDate:'2026-11-05'});assert.equal((await post(expense)).statusCode,200);const d=await dashboard(),rani=d.members.find((m:any)=>m.code==='rani');assert.equal(rani.savingsPaise,140000);assert.equal(rani.principalPaise,190000);assert.equal(d.savingsPaise,500000);assert.equal(d.principalPaise,490000);assert.equal(d.enterprises[0].expensesPaise,215000);assert.equal(d.enterprises[0].cashSurplusPaise,85000);const groups=(await call('GET','/v1/groups',manager)).json();assert.equal(groups.groups.find((g:any)=>g.code==='udaan').savingsPaise,380000);const meeting=(await call('GET',`/v1/meetings/${snap.meetings[0].id}`,manager)).json();assert.equal(meeting.cashReceivedPaise,30000);});
test('A13 controlled close/post race rejects the posting that follows submission',async()=>{await post(action());const attendance=snap.attendance[0];await post(op('meeting.attendance_set',{attendanceId:attendance.id,meetingId:attendance.meetingId,memberId:attendance.memberId,status:'present',expectedVersion:1}));const meeting=(await call('GET',`/v1/meetings/${attendance.meetingId}`,sakhi)).json().meeting;const identity=await transaction(c=>authenticate(c,hash(sakhi.token)));let entered!:()=>void,release!:()=>void;const held=new Promise<void>(r=>entered=r),gate=new Promise<void>(r=>release=r);const close=mutate(identity,op('meeting.submit',{meetingId:meeting.id,expectedVersion:meeting.version}),{afterLock:async()=>{entered();await gate;}});await held;const postAfter=mutate(identity,action()).then(()=>({code:'ACCEPTED'}),e=>({code:e.code}));try{let blocked=false;for(let n=0;n<100;n++){const locks=await pool.query("SELECT count(*)::integer AS n FROM pg_stat_activity WHERE datname=current_database() AND wait_event_type='Lock' AND query LIKE 'SELECT cursor FROM sync_clock%'");if(locks.rows[0].n){blocked=true;break;}}assert.equal(blocked,true);release();await close;assert.equal((await postAfter).code,'MEETING_CLOSED');assert.equal((await dashboard()).savingsPaise,500000);}finally{release();await close;}});
test('A11 stale member profile retains winning record and rejects original intent',async()=>{
 const member=snap.members.find((m:any)=>m.code==='rani');
 const first=op('member.update',{memberId:member.id,expectedVersion:member.version,patch:{displayName:'Rani Mahto Updated'}});
 assert.equal((await post(first)).statusCode,200);
 const stale=op('member.update',{memberId:member.id,expectedVersion:member.version,patch:{livelihoodCategory:'tailoring'}});
 const response=await post(stale);
 assert.equal(response.statusCode,409);assert.equal(response.json().error.code,'VERSION_CONFLICT');
 assert.equal(response.json().error.currentRecord.displayName,'Rani Mahto Updated');
 assert.equal(stale.payload.expectedVersion,member.version);
 const corrected=op('member.update',{...stale.payload,expectedVersion:response.json().error.currentRecord.version});
 assert.equal((await post(corrected)).statusCode,200);
 assert.equal((await dashboard()).savingsPaise,480000);
});

test('group lifecycle is manager-only and assigned empty groups are visible',async()=>{
 const groupId=randomUUID();const create=op('group.create',{groupId,code:'new-group',displayName:'New group',villageLabel:'Sample village',assignedActorId:sakhi.actor.id});
 assert.equal((await post(create)).statusCode,403);
 assert.equal((await post(create,participant)).statusCode,403);
 assert.equal((await post(create,manager)).statusCode,200);
 assert.equal((await post(create,manager)).json().replayed,true);
 assert.ok((await call('GET','/v1/bootstrap',sakhi)).json().groups.some((g:any)=>g.id===groupId));
 assert.equal((await post(op('group.update',{groupId,expectedVersion:1,displayName:'Renamed group',villageLabel:'Sample village'}),manager)).statusCode,200);
 assert.equal((await post(op('group.update',{groupId,expectedVersion:1,displayName:'Stale',villageLabel:'Sample village'}),manager)).json().error.code,'VERSION_CONFLICT');
});
test('scheduled meetings seed attendance and enforce assignment and duplicate date',async()=>{
 const body={meetingId:randomUUID(),groupId:snap.groups[0].id,businessDate:'2026-11-06'};
 assert.equal((await post(op('meeting.create',body),participant)).statusCode,403);
 const result=await post(op('meeting.create',body));assert.equal(result.statusCode,200,result.body);
 const detail=(await call('GET',`/v1/meetings/${body.meetingId}`,sakhi)).json();
 assert.equal(detail.attendance.length,4);assert.equal(detail.cashReceivedPaise,0);
 assert.equal((await post(op('meeting.create',{...body,meetingId:randomUUID()}))).statusCode,400);
});
test('enterprise onboarding starts at zero and update preserves ledger and owner',async()=>{
 const enterpriseId=randomUUID(),memberId=snap.members[0].id;
 const result=await post(op('enterprise.create',{enterpriseId,memberId,name:'Tailoring',businessPlan:'Buy fabric after confirmed orders'}));assert.equal(result.statusCode,200,result.body);
 let detail=(await call('GET',`/v1/enterprises/${enterpriseId}`,sakhi)).json();assert.equal(detail.enterprise.cashSurplusPaise,0);
 assert.equal((await post(op('enterprise.update',{enterpriseId,expectedVersion:1,name:'Tailoring business',businessPlan:'Review costs weekly'}))).statusCode,200);
 assert.equal((await post(op('enterprise.update',{enterpriseId,expectedVersion:1,name:'Stale',businessPlan:''}))).json().error.code,'VERSION_CONFLICT');
 assert.equal((await post(op('enterprise.create',{enterpriseId:randomUUID(),memberId,name:'Forbidden',businessPlan:''}),participant)).statusCode,403);
});
test('history endpoints bound pages without changing canonical financial totals',async()=>{
 await post(action());await post(action('savings_deposit',10000));
 const memberId=snap.members.find((m:any)=>m.code==='rani').id;
 const first=(await call('GET',`/v1/members/${memberId}/passbook?limit=1&offset=0`,sakhi)).json();
 const next=(await call('GET',`/v1/members/${memberId}/passbook?limit=1&offset=1`,sakhi)).json();
 assert.equal(first.transactions.length,1);assert.equal(first.total,2);assert.notEqual(first.transactions[0].id,next.transactions[0].id);
 assert.equal(first.member.savingsPaise,150000);assert.equal(next.member.savingsPaise,150000);
 assert.equal((await call('GET','/v1/groups?limit=501',manager)).statusCode,400);
});

test('Sakhi visit intake is scoped, idempotent and follow-up requires current version',async()=>{
 const member=snap.members[0],visitId=randomUUID();const create=op('visit.create',{visitId,memberId:member.id,businessDate:'2026-11-05',topic:'savings',notes:'Explained confirmed and pending savings',nextVisitDate:'2026-11-12'});
 assert.equal((await post(create,participant)).statusCode,403);
 const r=await post(create);assert.equal(r.statusCode,200,r.body);assert.equal((await post(create)).json().replayed,true);
 assert.equal((await call('GET','/v1/bootstrap',sakhi)).json().sakhiVisits.length,1);
 assert.equal((await call('GET','/v1/bootstrap',participant)).json().sakhiVisits.length,0);
 assert.equal((await post(op('visit.complete',{visitId,expectedVersion:1,outcome:'Participant completed the task'}),manager)).statusCode,200);
 assert.equal((await post(op('visit.complete',{visitId,expectedVersion:1,outcome:'Stale'}),manager)).json().error.code,'VERSION_CONFLICT');
});

test('content publishing is scoped, versioned, replay-safe and retains draft disclosure',async()=>{
 const original=(await call('GET','/v1/content',manager)).json();
 const cards=structuredClone(original.cards);cards[0].locales.en.title='Updated contribution help';
 const body={operationId:randomUUID(),expectedRevision:0,cards};
 assert.equal((await call('POST','/v1/content',sakhi,body)).statusCode,403);
 const publish=await call('POST','/v1/content',manager,body);assert.equal(publish.statusCode,200,publish.body);assert.equal(publish.json().revision,1);
 assert.equal((await call('POST','/v1/content',manager,body)).json().replayed,true);
 assert.equal((await call('POST','/v1/content',manager,{...body,operationId:randomUUID()})).json().error.code,'VERSION_CONFLICT');
 const downloaded=(await call('GET','/v1/content',participant)).json();assert.equal(downloaded.cards[0].locales.en.title,'Updated contribution help');assert.equal(downloaded.reviewStatus,'draft-not-tuif-approved');
});

test('identity mapping controls roles and session expiry independently of token claims',async()=>{
 const {identitySession}=await import('../src/identity.js');
 const subject={iss:'https://cognito-idp.ap-south-1.amazonaws.com/ap-south-1_Test',sub:'test-mapped-person',exp:Math.floor(Date.now()/1000)+120};
 await assert.rejects(identitySession(subject),(e:any)=>e.code==='FORBIDDEN');
 await pool.query('INSERT INTO external_identities(dataset_id,issuer,subject,actor_id) VALUES($1,$2,$3,$4)',[sakhi.datasetId,subject.iss,subject.sub,sakhi.actor.id]);
 const signedIn=await identitySession(subject);
 assert.equal(signedIn.actor.role,'sakhi');
 assert.ok(Date.parse(signedIn.expiresAt)<=subject.exp*1000);
 assert.equal((await call('GET','/v1/bootstrap',signedIn)).json().members.length,4);
 await pool.query('UPDATE external_identities SET enabled=false WHERE dataset_id=$1',[sakhi.datasetId]);
 await assert.rejects(identitySession(subject),(e:any)=>e.code==='FORBIDDEN');
 await assert.rejects(identitySession({...subject,exp:1}),(e:any)=>e.code==='SESSION_EXPIRED');
});
