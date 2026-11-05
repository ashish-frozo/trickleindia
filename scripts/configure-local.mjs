import { randomBytes, createHash } from 'node:crypto';
import { writeFile, mkdir, access } from 'node:fs/promises';
import { userInfo } from 'node:os';
const root=new URL('../',import.meta.url);
await mkdir(new URL('.local/',root),{recursive:true});
try {await access(new URL('.env',root));console.log('Existing .env retained');}
catch {
 const code=randomBytes(18).toString('base64url');
 await writeFile(new URL('.local/demo-access-code',root),code,{mode:0o600});
 const database=`postgresql://${encodeURIComponent(userInfo().username)}@127.0.0.1:${process.env.POP_PG_PORT??55432}/pop_demo`;
 await writeFile(new URL('.env',root),`DATABASE_URL=${database}\nDEMO_MODE=true\nDEMO_ACCESS_CODE_HASH=${createHash('sha256').update(code).digest('hex')}\nALLOW_DEMO_RESET=true\nALLOW_DEMO_FAULTS=false\nHOST=127.0.0.1\nPORT=${process.env.POP_API_PORT??3000}\nCORS_ORIGINS=http://localhost:${process.env.POP_WEB_PORT??8080},http://127.0.0.1:${process.env.POP_WEB_PORT??8080}\n`,{mode:0o600});
 console.log('Local configuration generated. Access code is in ignored .local/demo-access-code.');
}
