/** Uses the same audited/versioned manager authorization as the API. */
import {readFile} from 'node:fs/promises';
import {pool,transaction} from './db.js';
import {authenticate} from './mutations.js';
import {hash} from './domain.js';
import {saveStaff} from './administration.js';
try {
 if(process.env.DEMO_MODE!=='false')throw new Error('Set DEMO_MODE=false explicitly');
 if(!process.argv[2]||!process.env.POP_SESSION_TOKEN)throw new Error('Usage: POP_SESSION_TOKEN=... provision-identity.ts staff-envelope.json');
 const identity=await transaction(c=>authenticate(c,hash(process.env.POP_SESSION_TOKEN!)));
 console.log(JSON.stringify(await saveStaff(identity,JSON.parse(await readFile(process.argv[2],'utf8')))));
} finally {await pool.end();}
