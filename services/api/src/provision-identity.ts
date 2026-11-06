/** Explicit operator-run provisioning; never accepts role claims from sign-in. */
import {readFile} from 'node:fs/promises';
import {randomUUID} from 'node:crypto';
import {z} from 'zod';
import {pool,transaction,active,put} from './db.js';
const schema=z.strictObject({issuer:z.url().startsWith('https://cognito-idp.'),subject:z.string().min(1).max(200),displayName:z.string().min(1).max(100),role:z.enum(['manager','sakhi','participant']),memberId:z.uuid().optional(),groupIds:z.array(z.uuid()).max(1000).default([])});
try {
 if(process.env.DEMO_MODE==='true')throw new Error('Production identity provisioning cannot run in demo mode');
 const file=process.argv[2];if(!file)throw new Error('Usage: provision-identity.ts private-identity.json');
 const input=schema.parse(JSON.parse(await readFile(file,'utf8')));
 const id=await transaction(async c=>{
  const d=await active(c);await c.query('SELECT cursor FROM sync_clock WHERE dataset_id=$1 FOR UPDATE',[d.id]);
  if((await c.query('SELECT 1 FROM external_identities WHERE dataset_id=$1 AND issuer=$2 AND subject=$3',[d.id,input.issuer,input.subject])).rowCount)throw new Error('Identity already mapped');
  if(input.role==='participant'&&!input.memberId)throw new Error('Participant requires existing memberId');
  if(input.memberId&&!(await c.query("SELECT 1 FROM records WHERE dataset_id=$1 AND entity_type='members' AND id=$2",[d.id,input.memberId])).rowCount)throw new Error('Member missing');
  for(const group of input.groupIds)if(!(await c.query("SELECT 1 FROM records WHERE dataset_id=$1 AND entity_type='groups' AND id=$2",[d.id,group])).rowCount)throw new Error('Group missing');
  const actorId=randomUUID(),now=new Date().toISOString();
  await put(c,'actors',{id:actorId,datasetId:d.id,version:1,createdAt:now,updatedAt:now,displayName:input.displayName,role:input.role,memberId:input.memberId});
  for(const group of input.groupIds)await c.query('INSERT INTO actor_groups VALUES($1,$2,$3)',[d.id,actorId,group]);
  await c.query('INSERT INTO external_identities(dataset_id,issuer,subject,actor_id) VALUES($1,$2,$3,$4)',[d.id,input.issuer,input.subject,actorId]);
  return actorId;
 });
 console.log(`Identity mapped to actor ${id}`);
} finally {await pool.end();}
