import { randomUUID } from 'node:crypto';
import { transaction, active, snapshot, assignments, put, type Client } from './db.js';
import { envelope, payloads, fail, canonical, hash, effective, sum, normalizeName, type Entity, type Row } from './domain.js';

export type Identity = { actor: Row; datasetId: string; tokenHash: string };
export type Change = { entityType: Entity; record: Row };
export async function authenticate(c: Client, tokenHash: string): Promise<Identity> {
  const result = await c.query('SELECT s.dataset_id,s.actor_id FROM sessions s JOIN datasets d ON d.id=s.dataset_id AND d.active WHERE s.token_hash=$1 AND s.expires_at>now()',[tokenHash]);
  if (!result.rowCount) fail('SESSION_EXPIRED',401);
  const {dataset_id,actor_id} = result.rows[0];
  const actor = (await c.query("SELECT body FROM records WHERE dataset_id=$1 AND entity_type='actors' AND id=$2",[dataset_id,actor_id])).rows[0]?.body;
  if (!actor || actor.enabled===false) fail('SESSION_EXPIRED',401);
  return {actor,datasetId:dataset_id,tokenHash};
}
export async function mutate(identity: Identity, input: unknown, hooks?: { afterLock?: () => Promise<void> }) {
  const parsed = envelope.safeParse(input);
  if (!parsed.success) fail('INVALID_PAYLOAD');
  const op = parsed.data;
  const validated = payloads[op.kind].safeParse(op.payload);
  if (!validated.success) fail(op.kind==='transaction.post' && validated.error.issues.some(i=>i.path[0]==='amountPaise') ? 'INVALID_AMOUNT' : 'INVALID_PAYLOAD');
  const p = validated.data as Record<string, any>;
  const payloadHash = hash(canonical(op));
  return transaction(async c => {
    const d = await active(c);
    if (d.id !== op.datasetId || d.id !== identity.datasetId) fail('DATASET_MISMATCH',409);
    await c.query('SELECT cursor FROM sync_clock WHERE dataset_id=$1 FOR UPDATE',[d.id]);
    // Reset may have committed while this request waited for the old clock.
    if ((await active(c)).id !== d.id) fail('DATASET_MISMATCH',409);
    const {actor} = await authenticate(c, identity.tokenHash);
    await hooks?.afterLock?.();
    const s = await snapshot(c,d.id);
    const groups = await assignments(c,d.id,actor.id);
    const mustRole = (...roles: string[]) => { if (!roles.includes(actor.role)) fail('FORBIDDEN',403); };
    const find = (entity: Entity, id: string): Row => s[entity].find(r=>r.id===id) ?? fail('NOT_FOUND',404);
    const groupAccess = (groupId: string) => { if (actor.role !== 'manager' && !groups.includes(groupId)) fail('FORBIDDEN',403); };
    const memberAccess = (id: string) => { const m=find('members',id); if(actor.role==='participant') { if(m.id!==actor.memberId) fail('FORBIDDEN',403); } else groupAccess(m.groupId); return m; };
    const currentVersion = (r: Row, v: number) => { if(r.version!==v) fail('VERSION_CONFLICT',409,{currentVersion:r.version,currentRecord:r}); };
    const openMeeting = (id: string) => { const m=find('meetings',id);groupAccess(m.groupId);if(m.status!=='open') fail('MEETING_CLOSED',409,{currentRecord:m});return m; };
    // Authorize the current operation before returning any stored receipt.
    if (['member.create','member.update','meeting.attendance_set','transaction.post'].includes(op.kind)) mustRole('sakhi');
    if(op.kind==='visit.create') mustRole('sakhi');
    if(op.kind==='visit.complete') {mustRole('sakhi','manager');const visit=find('sakhiVisits',p.visitId);groupAccess(visit.groupId);if(actor.role==='sakhi'&&visit.sakhiId!==actor.id)fail('FORBIDDEN',403);}
    if(op.kind.startsWith('group.')) mustRole('manager');
    if(op.kind==='meeting.create') {mustRole('manager','sakhi');groupAccess(p.groupId);}
    if(op.kind==='enterprise.create') mustRole('manager','sakhi');
    if(op.kind==='enterprise.update') {mustRole('manager','sakhi');memberAccess(find('enterprises',p.enterpriseId).memberId);}
    if(op.kind==='transaction.reverse') mustRole('manager');
    if(op.kind==='meeting.submit') { mustRole('sakhi','manager');groupAccess(find('meetings',p.meetingId).groupId); }
    if(p.memberId && op.kind!=='member.create') memberAccess(p.memberId);
    if(op.kind==='member.create') groupAccess(p.groupId);
    if(op.kind==='support.update') { const r=find('supportRequests',p.requestId); if(actor.role!=='manager' && (actor.role!=='sakhi' || r.assignedActorId!==actor.id || !groups.includes(r.groupId))) fail('FORBIDDEN',403); }
    const prior = await c.query('SELECT payload_hash,result FROM operation_receipts WHERE dataset_id=$1 AND actor_id=$2 AND operation_id=$3',[d.id,actor.id,op.operationId]);
    if(prior.rowCount) { if(prior.rows[0].payload_hash!==payloadHash) fail('OPERATION_ID_REUSED',409); return {...prior.rows[0].result,replayed:true}; }
    const changes: Change[]=[];
    const now = new Date().toISOString();
    const save = async (entity: Entity, data: Record<string,any>, existing?: Row): Promise<Row> => {
      const r = {...existing,...data,datasetId:d.id,version:existing ? existing.version+1 : 1,createdAt:existing?.createdAt ?? now,updatedAt:now,originOperationId:op.operationId} as Row;
      await put(c,entity,r);changes.push({entityType:entity,record:r});return r;
    };
    const unused = (entity: Entity,id: string, code='INVALID_PAYLOAD') => { if(s[entity].some(r=>r.id===id)) fail(code,409); };
    switch(op.kind) {
      case 'visit.create': {
        unused('sakhiVisits',p.visitId);const member=memberAccess(p.memberId);
        if(p.nextVisitDate && p.nextVisitDate < p.businessDate)fail('INVALID_PAYLOAD');
        if(p.businessDate>new Date(Date.now()+19800000).toISOString().slice(0,10))fail('INVALID_PAYLOAD');
        const {visitId,...fields}=p;await save('sakhiVisits',{...fields,id:visitId,groupId:member.groupId,sakhiId:actor.id,status:p.nextVisitDate?'follow_up':'recorded'});break;
      }
      case 'visit.complete': {
        const visit=find('sakhiVisits',p.visitId);currentVersion(visit,p.expectedVersion);
        if(visit.status!=='follow_up')fail('INVALID_PAYLOAD');
        await save('sakhiVisits',{status:'completed',outcome:p.outcome,completedAt:now},visit);break;
      }
      case 'group.create': {
        unused('groups',p.groupId);
        if(s.groups.some(g=>g.code.toLowerCase()===p.code.toLowerCase())) fail('INVALID_PAYLOAD');
        if(find('actors',p.assignedActorId).role!=='sakhi') fail('INVALID_PAYLOAD');
        await save('groups',{id:p.groupId,code:p.code,displayName:p.displayName,villageLabel:p.villageLabel});
        await c.query('INSERT INTO actor_groups VALUES($1,$2,$3)',[d.id,p.assignedActorId,p.groupId]);
        break;
      }
      case 'group.update': {
        const g=find('groups',p.groupId);currentVersion(g,p.expectedVersion);
        await save('groups',{displayName:p.displayName,villageLabel:p.villageLabel},g);break;
      }
      case 'meeting.create': {
        find('groups',p.groupId);unused('meetings',p.meetingId);
        if(s.meetings.some(m=>m.groupId===p.groupId&&m.businessDate===p.businessDate)) fail('INVALID_PAYLOAD');
        await save('meetings',{id:p.meetingId,groupId:p.groupId,businessDate:p.businessDate,status:'open',submittedAt:null,submittedBy:null});
        for(const m of s.members.filter(m=>m.groupId===p.groupId&&m.status==='active')) await save('attendance',{id:randomUUID(),meetingId:p.meetingId,memberId:m.id,status:'unmarked'});
        break;
      }
      case 'enterprise.create': {
        unused('enterprises',p.enterpriseId);memberAccess(p.memberId);
        if(s.enterprises.some(e=>e.memberId===p.memberId&&normalizeName(e.name)===normalizeName(p.name))) fail('INVALID_PAYLOAD');
        await save('enterprises',{id:p.enterpriseId,memberId:p.memberId,name:p.name,businessPlan:p.businessPlan,openingCashSalesPaise:0,openingCashExpensesPaise:0});break;
      }
      case 'enterprise.update': {
        const e=find('enterprises',p.enterpriseId);currentVersion(e,p.expectedVersion);
        await save('enterprises',{name:p.name,businessPlan:p.businessPlan},e);break;
      }
      case 'transaction.post': {
        unused('transactions',p.transactionId,'TRANSACTION_ID_REUSED');
        const member=memberAccess(p.memberId);
        let meeting: Row | undefined;
        const enterpriseEntry=p.type.startsWith('enterprise_');
        if(enterpriseEntry) {
          if(!p.enterpriseId || p.meetingId || p.loanId || !p.category) fail('INVALID_PAYLOAD');
          if(find('enterprises',p.enterpriseId).memberId!==member.id) fail('INVALID_PAYLOAD');
        } else {
          if(!p.meetingId || p.enterpriseId || p.category) fail('INVALID_PAYLOAD');
          meeting=openMeeting(p.meetingId);
          if(meeting.groupId!==member.groupId || meeting.businessDate!==p.businessDate) fail('INVALID_PAYLOAD');
          if(p.type==='loan_principal_repayment') {
            if(!p.loanId) fail('INVALID_PAYLOAD');
            const loan=find('loans',p.loanId);
            if(loan.memberId!==member.id) fail('INVALID_PAYLOAD');
            const remaining=loan.openingPrincipalPaise-sum(effective(s).filter(t=>t.loanId===loan.id && t.type==='loan_principal_repayment'),'amountPaise');
            if(p.amountPaise>remaining) fail('LOAN_BALANCE_EXCEEDED',409,{remainingPrincipalPaise:remaining});
          } else if(p.loanId) fail('INVALID_PAYLOAD');
        }
        if(p.businessDate > new Date(Date.now()+19800000).toISOString().slice(0,10)) fail('INVALID_PAYLOAD');
        const {transactionId,...fields}=p;
        await save('transactions',{...fields,id:transactionId,operationId:op.operationId,groupId:member.groupId,createdByActorId:actor.id});
        if(meeting) await save('meetings',{},meeting);
        break;
      }
      case 'meeting.attendance_set': {
        const meeting=openMeeting(p.meetingId), member=memberAccess(p.memberId);
        if(member.groupId!==meeting.groupId) fail('INVALID_PAYLOAD');
        const existing=s.attendance.find(a=>a.meetingId===meeting.id && a.memberId===member.id);
        if(existing) { currentVersion(existing,p.expectedVersion);if(existing.id!==p.attendanceId) fail('INVALID_PAYLOAD'); }
        else { if(p.expectedVersion!==0) fail('VERSION_CONFLICT',409,{currentVersion:0});unused('attendance',p.attendanceId); }
        await save('attendance',{id:p.attendanceId,meetingId:meeting.id,memberId:member.id,status:p.status},existing);
        await save('meetings',{},meeting);break;
      }
      case 'meeting.submit': {
        const meeting=openMeeting(p.meetingId);currentVersion(meeting,p.expectedVersion);
        if(!s.attendance.some(a=>a.meetingId===meeting.id && a.status!=='unmarked') || !effective(s).some(t=>t.meetingId===meeting.id)) fail('INVALID_PAYLOAD');
        await save('meetings',{status:'submitted',submittedBy:actor.id,submittedAt:now},meeting);break;
      }
      case 'member.create': {
        find('groups',p.groupId);unused('members',p.memberId);
        const candidates=s.members.filter(m=>m.groupId===p.groupId && m.status==='active' && normalizeName(m.displayName)===normalizeName(p.displayName));
        if(candidates.length) fail('POSSIBLE_DUPLICATE',409,{candidates:candidates.map(m=>({id:m.id,displayName:m.displayName}))});
        const {memberId,...fields}=p;await save('members',{...fields,id:memberId,openingSavingsPaise:0,status:'active'});break;
      }
      case 'member.update': {
        const m=memberAccess(p.memberId);currentVersion(m,p.expectedVersion);await save('members',p.patch,m);break;
      }
      case 'transaction.reverse': {
        unused('transactions',p.transactionId,'TRANSACTION_ID_REUSED');const original=find('transactions',p.originalTransactionId);
        if(original.type==='reversal' || original.reversedByTransactionId) fail('ALREADY_REVERSED',409);
        await save('transactions',{id:p.transactionId,operationId:op.operationId,memberId:original.memberId,groupId:original.groupId,type:'reversal',amountPaise:original.amountPaise,businessDate:d.business_date,createdByActorId:actor.id,originalTransactionId:original.id,originalType:original.type,reason:p.reason});
        await save('transactions',{reversedByTransactionId:p.transactionId},original);
        if(original.meetingId) await save('meetings',{},find('meetings',original.meetingId));break;
      }
      case 'support.create': {
        unused('supportRequests',p.requestId);const member=memberAccess(p.memberId);
        const owner=(await c.query('SELECT actor_id FROM actor_groups WHERE dataset_id=$1 AND group_id=$2 ORDER BY actor_id LIMIT 1',[d.id,member.groupId])).rows[0]?.actor_id;
        const counter=(await c.query('UPDATE sync_clock SET support_counter=support_counter+1 WHERE dataset_id=$1 RETURNING support_counter',[d.id])).rows[0].support_counter;
        await save('supportRequests',{id:p.requestId,memberId:member.id,groupId:member.groupId,category:p.category,description:p.description,source:'app',status:'open',assignedActorId:owner??null,reference:`DEMO-${String(counter).padStart(4,'0')}`,resolutionNote:null,resolvedAt:null});break;
      }
      case 'support.update': {
        const r=find('supportRequests',p.requestId);currentVersion(r,p.expectedVersion);
        if(r.status==='resolved') fail('INVALID_PAYLOAD');
        if(p.assignedActorId) {
          mustRole('manager');const owner=find('actors',p.assignedActorId);
          if(owner.role!=='sakhi' || !(await assignments(c,d.id,owner.id)).includes(r.groupId)) fail('INVALID_PAYLOAD');
        }
        if(p.status && !((r.status==='open' && p.status==='in_progress') || (r.status==='in_progress' && p.status==='resolved'))) fail('INVALID_PAYLOAD');
        if(p.status==='resolved' && !p.resolutionNote) fail('INVALID_PAYLOAD');
        if(p.resolutionNote && p.status!=='resolved') fail('INVALID_PAYLOAD');
        const {requestId,expectedVersion,...fields}=p;await save('supportRequests',{...fields,...(p.status==='resolved'?{resolvedAt:now}:{})},r);break;
      }
    }
    const cursor=(await c.query('UPDATE sync_clock SET cursor=cursor+1 WHERE dataset_id=$1 RETURNING cursor::text',[d.id])).rows[0].cursor;
    const audit={id:randomUUID(),datasetId:d.id,actorId:actor.id,action:op.kind,entityType:changes[0].entityType,entityId:changes[0].record.id,operationId:op.operationId,changedFields:Object.keys(p),reason:p.reason??null,clientCreatedAt:op.clientCreatedAt,timestamp:now};
    await c.query('INSERT INTO audit_events VALUES($1,$2,$3,$4,$5)',[audit.id,d.id,actor.id,op.operationId,audit]);
    await c.query('INSERT INTO change_events VALUES($1,$2,$3)',[d.id,cursor,JSON.stringify(changes)]);
    const result={operationId:op.operationId,status:'accepted',replayed:false,changeCursor:cursor,records:changes};
    await c.query('INSERT INTO operation_receipts VALUES($1,$2,$3,$4,$5)',[d.id,actor.id,op.operationId,payloadHash,result]);
    return result;
  });
}
