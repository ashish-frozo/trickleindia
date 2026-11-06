import {readFile} from 'node:fs/promises';
import {pool,transaction} from './db.js';
import {authenticate} from './mutations.js';
import {hash} from './domain.js';
import {dryRunImport,commitImport,rollbackImport} from './migration-import.js';
try {
 const command=process.argv[2],file=process.argv[3];
 if(process.env.DEMO_MODE!=='false'||!process.env.POP_SESSION_TOKEN||!file||!['dry-run','commit','rollback'].includes(command))throw new Error('Usage: DEMO_MODE=false POP_SESSION_TOKEN=... import-cli.ts dry-run|commit|rollback envelope.json');
 const identity=await transaction(c=>authenticate(c,hash(process.env.POP_SESSION_TOKEN!)));
 console.log(JSON.stringify(await ({'dry-run':dryRunImport,commit:commitImport,rollback:rollbackImport}[command]!)(identity,JSON.parse(await readFile(file,'utf8'))),null,2));
} finally {await pool.end();}
