import { CognitoJwtVerifier } from 'aws-jwt-verify';
import { randomBytes } from 'node:crypto';
import { transaction, active } from './db.js';
import { fail, hash } from './domain.js';

export function cognitoVerifier(userPoolId: string, clientId: string) {
  return CognitoJwtVerifier.create({userPoolId,clientId,tokenUse:'access'});
}
export type VerifiedSubject={sub:string;iss:string;exp:number};
/** Roles/assignments come from our database, never caller fields or token groups. */
export async function identitySession(subject:VerifiedSubject) {
  if(subject.exp*1000<=Date.now())fail('SESSION_EXPIRED',401);
  return transaction(async c=>{
    const dataset=await active(c);
    await c.query('SELECT cursor FROM sync_clock WHERE dataset_id=$1 FOR UPDATE',[dataset.id]);
    if((await active(c)).id!==dataset.id)fail('DATASET_MISMATCH',409);
    const mapped=await c.query("SELECT r.body FROM external_identities i JOIN records r ON r.dataset_id=i.dataset_id AND r.entity_type='actors' AND r.id=i.actor_id WHERE i.dataset_id=$1 AND i.issuer=$2 AND i.subject=$3 AND i.enabled",[dataset.id,subject.iss,subject.sub]);
    if(!mapped.rowCount)fail('FORBIDDEN',403);
    const token=randomBytes(32).toString('base64url');
    const expiresAt=new Date(Math.min(subject.exp*1000,Date.now()+8*3600000)).toISOString();
    await c.query('INSERT INTO sessions VALUES($1,$2,$3,$4)',[hash(token),dataset.id,mapped.rows[0].body.id,expiresAt]);
    return {token,expiresAt,offlineUntil:expiresAt,actor:mapped.rows[0].body,datasetId:dataset.id};
  });
}
