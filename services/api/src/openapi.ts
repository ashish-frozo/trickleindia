import { writeFile } from 'node:fs/promises';
import { z } from 'zod';
import { contentSchema } from './content.js';
import { payloads, entities } from './domain.js';
const ref=(name:string)=>({$ref:`#/components/schemas/${name}`});
const json=(schema:unknown)=>({'application/json':{schema}});
const record={type:'object',required:['id','datasetId','version','createdAt','updatedAt'],properties:{id:{type:'string',format:'uuid'},datasetId:{type:'string',format:'uuid'},version:{type:'integer',minimum:1},createdAt:{type:'string',format:'date-time'},updatedAt:{type:'string',format:'date-time'},originOperationId:{type:'string',format:'uuid'}},additionalProperties:true};
const records={type:'array',items:{type:'object',required:['entityType','record'],properties:{entityType:{type:'string',enum:entities},record:ref('Record')}}};
const schemas:Record<string,unknown>={Record:record,Error:{type:'object',required:['error','requestId'],properties:{requestId:{type:'string'},error:{type:'object',required:['code','messageKey','retryable'],properties:{code:{type:'string'},messageKey:{type:'string'},retryable:{type:'boolean'},fieldErrors:{type:'object'},currentVersion:{type:'integer'},currentRecord:ref('Record')},additionalProperties:true}}},Accepted:{type:'object',required:['operationId','status','replayed','changeCursor','records','requestId'],properties:{operationId:{type:'string',format:'uuid'},status:{const:'accepted'},replayed:{type:'boolean'},changeCursor:{type:'string',pattern:'^[0-9]+$'},records,requestId:{type:'string'}}},Bootstrap:{type:'object',required:[...entities,'datasetId','cursor','serverTime','requestId'],properties:{...Object.fromEntries(entities.map(e=>[e,{type:'array',items:ref('Record')}])),datasetId:{type:'string',format:'uuid'},cursor:{type:'string'},serverTime:{type:'string',format:'date-time'},contentVersion:{type:'integer'},requestId:{type:'string'}}},Changes:{type:'object',required:['datasetId','records','nextCursor','highWaterCursor','hasMore','requestId'],properties:{datasetId:{type:'string',format:'uuid'},records,nextCursor:{type:'string'},highWaterCursor:{type:'string'},hasMore:{type:'boolean'},requestId:{type:'string'}}}};
const errors=Object.fromEntries([400,401,403,404,409,429,503].map(status=>[status,{description:'Structured domain error; inspect error.code and retryable',content:json(ref('Error'))}]));
const response=(schema:unknown={type:'object',additionalProperties:true})=>({'200':{description:'Authorized canonical result',content:json(schema)},...errors});
const query=(name:string,schema:unknown,required=false)=>({in:'query',name,required,schema});
const pagination=[query('offset',{type:'integer',minimum:0,default:0}),query('limit',{type:'integer',minimum:1,maximum:500,default:100})];
const paths:Record<string,any>={};
for(const path of ['/bootstrap','/changes','/dashboard','/groups','/members/{id}/passbook','/meetings/{id}','/enterprises/{id}','/support-requests','/support-requests/{id}','/audit-events','/content','/operations/{id}']) {
 const parameters:any[]=[];if(path.includes('{id}'))parameters.push({in:'path',name:'id',required:true,schema:{type:'string',format:'uuid'}});
 if(path==='/changes')parameters.push(query('datasetId',{type:'string',format:'uuid'},true),query('after',{type:'string',pattern:'^[0-9]{1,19}$'},true),query('limit',{type:'integer',minimum:1,maximum:500,default:100}));
 if(path==='/operations/{id}')parameters.push(query('datasetId',{type:'string',format:'uuid'},true));
 if(['/audit-events','/support-requests','/groups','/members/{id}/passbook','/meetings/{id}','/enterprises/{id}'].includes(path))parameters.push(...pagination);
 if(path==='/support-requests')parameters.push(query('groupId',{type:'string',format:'uuid'}),query('status',{type:'string',enum:['open','in_progress','resolved']}));
 paths['/v1'+path]={get:{operationId:'get'+path.replace(/[^a-zA-Z]/g,''),summary:path,security:[{bearerAuth:[]}],parameters,responses:response(path==='/bootstrap'?ref('Bootstrap'):path==='/changes'?ref('Changes'):path==='/operations/{id}'?ref('Accepted'):undefined)}};
}
const kinds=Object.entries(payloads).map(([kind,payload])=>z.toJSONSchema(z.strictObject({datasetId:z.uuid(),operationId:z.uuid(),kind:z.literal(kind),clientCreatedAt:z.iso.datetime(),payload})));
schemas.Mutation={oneOf:kinds};
paths['/v1/mutations']={post:{operationId:'mutate',summary:'Idempotent domain mutation',security:[{bearerAuth:[]}],description:'Freeze the complete envelope on enqueue. Retry the same operationId and payload. Changed replay is rejected. Financial transactionId is independently unique within the dataset.',requestBody:{required:true,content:json(ref('Mutation'))},responses:response(ref('Accepted'))}};
for(const [path,schema] of Object.entries({
 '/v1/demo/session':z.strictObject({actorCode:z.enum(['kavita','rani-user','arun']),accessCode:z.string().max(200)}),
 '/v1/demo/reset':z.strictObject({accessCode:z.string().max(200),confirmation:z.literal('RESET DEMO')}),
 '/v1/demo/whatsapp-events':z.strictObject({simulatedMessageId:z.uuid(),demoContactCode:z.literal('demo-contact-rani'),topicCode:z.literal('expense_help')})
}))paths[path]={post:{operationId:path.split('/').at(-1),summary:path,security:path.endsWith('session')?[]:[{bearerAuth:[]}],requestBody:{required:true,content:json(z.toJSONSchema(schema))},responses:response()}};
paths['/v1/auth/config']={get:{operationId:'authConfig',security:[],responses:response()}};
paths['/v1/auth/session']={post:{operationId:'identitySession',security:[],requestBody:{required:true,content:json(z.toJSONSchema(z.strictObject({accessToken:z.string().min(20).max(16384)})))},responses:response()}};
paths['/v1/content'].post={operationId:'publishContent',security:[{bearerAuth:[]}],summary:'Manager-only versioned draft content publication',requestBody:{required:true,content:json(z.toJSONSchema(contentSchema))},responses:response()};
for(const path of ['/healthz','/readyz'])paths[path]={get:{operationId:path.slice(1),summary:path,security:[],responses:response()}};
await writeFile(new URL('../../../docs/openapi.json',import.meta.url),JSON.stringify({openapi:'3.1.0',info:{title:'PoP 2.0 demo API',version:'1.0.0',description:'Synthetic local proposal demonstration. Demo endpoints are disabled outside configured demo mode.'},servers:[{url:'http://127.0.0.1:3000'}],components:{securitySchemes:{bearerAuth:{type:'http',scheme:'bearer'}},schemas},paths},null,2)+'\n');
