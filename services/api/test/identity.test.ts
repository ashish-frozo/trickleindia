import {test} from 'node:test';
import assert from 'node:assert/strict';
import {generateKeyPairSync,sign} from 'node:crypto';
import {cognitoVerifier} from '../src/identity.js';
const {publicKey,privateKey}=generateKeyPairSync('rsa',{modulusLength:2048});
const poolId='ap-south-1_AuditTest',clientId='test-client';
const verifier=cognitoVerifier(poolId,clientId);
verifier.cacheJwks({keys:[{...publicKey.export({format:'jwk'}),kid:'local-test',use:'sig',alg:'RS256'}]});
const jwt=(extra:Record<string,unknown>={})=>{
 const header=Buffer.from(JSON.stringify({alg:'RS256',kid:'local-test'})).toString('base64url');
 const payload=Buffer.from(JSON.stringify({sub:'mapped-user',iss:`https://cognito-idp.ap-south-1.amazonaws.com/${poolId}`,token_use:'access',client_id:clientId,exp:Math.floor(Date.now()/1000)+300,iat:Math.floor(Date.now()/1000),...extra})).toString('base64url');
 return `${header}.${payload}.${sign('RSA-SHA256',Buffer.from(`${header}.${payload}`),privateKey).toString('base64url')}`;
};
test('Cognito verifier accepts a valid signed access token',async()=>{assert.equal((await verifier.verify(jwt())).sub,'mapped-user');});
test('Cognito verifier rejects wrong client, issuer, token type, expiry and altered signature',async()=>{
 for(const change of [{client_id:'attacker'},{iss:'https://attacker.example'},{token_use:'id'},{exp:1}]) await assert.rejects(verifier.verify(jwt(change)));
 const valid=jwt();await assert.rejects(verifier.verify(valid.slice(0,-20)+'x'.repeat(20)));
});
