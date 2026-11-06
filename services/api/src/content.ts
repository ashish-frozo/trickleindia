import {randomUUID} from 'node:crypto';
import {readFile} from 'node:fs/promises';
import {z} from 'zod';
import {fail,hash,canonical} from './domain.js';
import {transaction,active,type Client} from './db.js';
import {authenticate,type Identity} from './mutations.js';
const locale=z.strictObject({title:z.string().min(1).max(200),steps:z.array(z.string().min(1).max(1000)).min(1).max(20),audioScript:z.string().min(1).max(5000),audioAsset:z.null(),audioReviewStatus:z.literal('not-produced')});
export const contentSchema=z.strictObject({operationId:z.uuid(),expectedRevision:z.number().int().nonnegative(),cards:z.array(z.strictObject({id:z.string().regex(/^[a-z0-9-]+$/).max(80),version:z.number().int().positive(),keywords:z.array(z.string().max(100)).max(50),reviewStatus:z.literal('draft-not-tuif-approved'),locales:z.strictObject({en:locale,hi:locale})})).min(1).max(100)});
export async function content(c:Client,datasetId:string){
 const stored=await c.query('SELECT revision,body FROM content_packs WHERE dataset_id=$1 ORDER BY revision DESC LIMIT 1',[datasetId]);
 if(stored.rowCount)return {...stored.rows[0].body,revision:stored.rows[0].revision};
 return {...JSON.parse(await readFile(new URL('../../../PoP_2_Demo_Coding_Pack/assets/content_cards.json',import.meta.url),'utf8')),revision:0};
}
export async function publishContent(identity:Identity,input:unknown){
 const parsed=contentSchema.safeParse(input);if(!parsed.success)fail('INVALID_PAYLOAD');const p=parsed.data;
 if(new Set(p.cards.map(c=>c.id)).size!==p.cards.length)fail('INVALID_PAYLOAD');
 return transaction(async c=>{
  const d=await active(c);if(d.id!==identity.datasetId)fail('DATASET_MISMATCH',409);
  await c.query('SELECT cursor FROM sync_clock WHERE dataset_id=$1 FOR UPDATE',[d.id]);
  const {actor}=await authenticate(c,identity.tokenHash);if(actor.role!=='manager')fail('FORBIDDEN',403);
  const fingerprint=hash(canonical(p));
  const prior=await c.query('SELECT payload_hash,result FROM operation_receipts WHERE dataset_id=$1 AND actor_id=$2 AND operation_id=$3',[d.id,actor.id,p.operationId]);
  if(prior.rowCount){if(prior.rows[0].payload_hash!==fingerprint)fail('OPERATION_ID_REUSED',409);return {...prior.rows[0].result,replayed:true};}
  const current=await content(c,d.id);if(current.revision!==p.expectedRevision)fail('VERSION_CONFLICT',409,{currentVersion:current.revision});
  const revision=current.revision+1,body={schemaVersion:1,contentVersion:`published-${revision}`,label:'Demo app instructions',reviewStatus:'draft-not-tuif-approved',audioAssetsIncluded:false,cards:p.cards};
  await c.query('INSERT INTO content_packs(dataset_id,revision,body,published_by) VALUES($1,$2,$3,$4)',[d.id,revision,body,actor.id]);
  const audit={id:randomUUID(),datasetId:d.id,actorId:actor.id,action:'content.publish',entityType:'contentPacks',entityId:`revision-${revision}`,operationId:p.operationId,changedFields:['cards'],timestamp:new Date().toISOString()};
  await c.query('INSERT INTO audit_events VALUES($1,$2,$3,$4,$5)',[audit.id,d.id,actor.id,p.operationId,audit]);
  const result={...body,revision,replayed:false};
  await c.query('INSERT INTO operation_receipts VALUES($1,$2,$3,$4,$5)',[d.id,actor.id,p.operationId,fingerprint,result]);
  return result;
 });
}
