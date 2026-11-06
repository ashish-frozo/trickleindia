import { buildApp } from './app.js';
import { pool } from './db.js';
const assistant = process.env.ASSISTANT_ENDPOINT && process.env.ASSISTANT_API_KEY && process.env.ASSISTANT_MODEL ? {endpoint:process.env.ASSISTANT_ENDPOINT,apiKey:process.env.ASSISTANT_API_KEY,model:process.env.ASSISTANT_MODEL} : undefined;
if ([process.env.ASSISTANT_ENDPOINT,process.env.ASSISTANT_API_KEY,process.env.ASSISTANT_MODEL].some(Boolean) && !assistant) throw new Error('Configure all three ASSISTANT settings or leave all unset');
const app=await buildApp({assistant,demoMode:process.env.DEMO_MODE==='true',accessCodeHash:process.env.DEMO_ACCESS_CODE_HASH??'',allowReset:process.env.ALLOW_DEMO_RESET==='true',allowFaults:process.env.ALLOW_DEMO_FAULTS==='true',origins:(process.env.CORS_ORIGINS??'http://localhost:8080').split(','),cognito:process.env.COGNITO_USER_POOL_ID?{userPoolId:process.env.COGNITO_USER_POOL_ID,clientId:process.env.COGNITO_CLIENT_ID??'',domain:process.env.COGNITO_DOMAIN??'',redirectUri:process.env.AUTH_REDIRECT_URI??''}:undefined});
await app.listen({host:process.env.HOST??'127.0.0.1',port:Number(process.env.PORT??3000)});
console.log('PoP demo API listening');
for(const signal of ['SIGINT','SIGTERM']) process.on(signal,async()=>{await app.close();await pool.end();process.exit(0);});
