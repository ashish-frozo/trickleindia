import { randomUUID } from 'node:crypto';
import { z } from 'zod';
import { transaction, active, snapshot, put } from './db.js';
import { authenticate, type Identity } from './mutations.js';
import { fail, hash, canonical, type Row } from './domain.js';
export async function simulate(i:Identity,input:unknown) {
 const parsed=z.strictObject({simulatedMessageId:z.uuid(),demoContactCode:z.literal('demo-contact-rani'),topicCode:z.literal('expense_help')}).safeParse(input);
 if(!parsed.success) fail('INVALID_PAYLOAD');const p=parsed.data;
 return transaction(async c=>{
  const d=await active(c);if(d.id!==i.datasetId) fail('DATASET_MISMATCH',409);
  await c.query('SELECT cursor FROM sync_clock WHERE dataset_id=$1 FOR UPDATE',[d.id]);
  const {actor}=await authenticate(c,i.tokenHash);if(actor.role!=='manager') fail('FORBIDDEN',403);
  const h=hash(canonical(p));const prior=await c.query('SELECT * FROM simulation_receipts WHERE dataset_id=$1 AND message_id=$2',[d.id,p.simulatedMessageId]);
  if(prior.rowCount) {if(prior.rows[0].payload_hash!==h) fail('OPERATION_ID_REUSED',409);return {...prior.rows[0].result,replayed:true};}
  const s=await snapshot(c,d.id);const member=s.members.find(m=>m.code==='rani')!;
  const owner=(await c.query('SELECT actor_id FROM actor_groups WHERE dataset_id=$1 AND group_id=$2 LIMIT 1',[d.id,member.groupId])).rows[0].actor_id;
  const clock=(await c.query('UPDATE sync_clock SET cursor=cursor+1,support_counter=support_counter+1 WHERE dataset_id=$1 RETURNING cursor::text,support_counter',[d.id])).rows[0];
  const now=new Date().toISOString();const r:Row={id:randomUUID(),datasetId:d.id,version:1,createdAt:now,updatedAt:now,originOperationId:p.simulatedMessageId,memberId:member.id,groupId:member.groupId,category:'expense_help',description:'Fictional request: help recording an expense.',source:'whatsapp_simulation',status:'open',assignedActorId:owner,reference:`DEMO-${String(clock.support_counter).padStart(4,'0')}`,resolutionNote:null,resolvedAt:null};
  await put(c,'supportRequests',r);const changes=[{entityType:'supportRequests',record:r}];
  await c.query('INSERT INTO change_events VALUES($1,$2,$3)',[d.id,clock.cursor,JSON.stringify(changes)]);
  const audit={id:randomUUID(),actorId:actor.id,action:'support.simulation_create',entityType:'supportRequests',entityId:r.id,operationId:p.simulatedMessageId,timestamp:now};
  await c.query('INSERT INTO audit_events VALUES($1,$2,$3,$4,$5)',[audit.id,d.id,actor.id,p.simulatedMessageId,audit]);
  const result={request:r,assignedActorId:owner,replayed:false,changeCursor:clock.cursor,records:changes};
  await c.query('INSERT INTO simulation_receipts VALUES($1,$2,$3,$4)',[d.id,p.simulatedMessageId,h,result]);return result;
 });
}
