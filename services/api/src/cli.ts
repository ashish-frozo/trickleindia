import { migrate, seed, pool } from './db.js';
try {
  if(process.argv[2]==='migrate') {await migrate();console.log('Migrations applied');}
  else if(process.argv[2]==='seed') {
    if(process.env.DEMO_MODE!=='true') throw new Error('Seed requires DEMO_MODE=true');
    console.log(`Synthetic dataset created: ${await seed()}`);
  } else throw new Error('Usage: cli.ts migrate|seed');
} finally { await pool.end(); }
