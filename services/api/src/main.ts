import { buildApp } from './app.js';
import { pool } from './db.js';
const app=await buildApp({demoMode:process.env.DEMO_MODE==='true',accessCodeHash:process.env.DEMO_ACCESS_CODE_HASH??'',allowReset:process.env.ALLOW_DEMO_RESET==='true',allowFaults:process.env.ALLOW_DEMO_FAULTS==='true',origins:(process.env.CORS_ORIGINS??'http://localhost:8080').split(',')});
await app.listen({host:process.env.HOST??'127.0.0.1',port:Number(process.env.PORT??3000)});
console.log('PoP demo API listening');
for(const signal of ['SIGINT','SIGTERM']) process.on(signal,async()=>{await app.close();await pool.end();process.exit(0);});
