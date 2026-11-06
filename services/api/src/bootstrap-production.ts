import {readFile} from 'node:fs/promises';
import {bootstrapProduction} from './administration.js';
import {pool} from './db.js';
try {
 if(process.env.DEMO_MODE!=='false')throw new Error('Set DEMO_MODE=false explicitly for production bootstrap');
 if(!process.argv[2])throw new Error('Usage: bootstrap-production.ts private-bootstrap.json');
 console.log(JSON.stringify(await bootstrapProduction(JSON.parse(await readFile(process.argv[2],'utf8')),false)));
} finally {await pool.end();}
