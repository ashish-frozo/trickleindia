// Run with NODE_PATH containing pptxgenjs/playwright/sharp and HTML2PPTX pointing to html2pptx.js.
const fs = require('fs'), path = require('path');
const PptxGenJS = require('pptxgenjs');
const html2pptx = require(process.env.HTML2PPTX);
const slides = [
 ['PoP 2.0', 'Field workflows. Clear records.', 'Local proposal walkthrough', ['Flutter Android and programme portal','Synthetic data; English and Hindi draft copy','Engineering progress, not production acceptance']],
 ['01 / Field use', 'Save once. Confirm after sync.', 'Sakhi practice', ['Open the member and review the group','Enter amount, type, date and note','Confirm; pending remains separate from confirmed','Restart offline, reconnect and verify one posting']],
 ['02 / Operations', 'Manage the working programme.', 'Implemented workflows', ['Member registration and profile editing','Group setup and meeting scheduling','Enterprise details, plans, sales and expense categories','Private Sakhi visits and follow-up outcomes']],
 ['03 / Programme view', 'Trace totals to their records.', 'Manager practice', ['Savings drill-down and scoped balance CSV','Activity paging, refresh and retry','Version-checked help content editor','Draft revisions retained for offline help']],
 ['04 / Recovery', 'Preserve the original intent.', 'When something goes wrong', ['Retry the same saved operation, not a new payment','Resolve conflicts against current server values','Use a reversal for a confirmed financial correction','Keep operation IDs; never share tokens or access codes']],
 ['05 / Verification', 'Evidence has a boundary.', 'Local checks', ['API tests cover scope, replay and ledger rules','UI tests cover large text and offline balance visibility','A test backup restored into an isolated database','Cloud identity callbacks and field UAT are unverified']],
 ['06 / Handover', 'Ready for review. Still a demo.', 'Next acceptance work', ['No TUIF AWS environment or approved repository supplied','Language review, recorded audio and live AI remain open','Actual TalkBack and representative-device timing remain','Use the closure register and training worksheet for sign-off']],
];
(async()=>{
 const dir=path.resolve('.local/training-slides');fs.mkdirSync(dir,{recursive:true});
 const pptx=new PptxGenJS();pptx.layout='LAYOUT_16x9';pptx.author='PoP project';pptx.subject='Local proposal and training';pptx.title='PoP 2.0 — local workflow training';
 for(let i=0;i<slides.length;i++){
  const [eyebrow,title,label,items]=slides[i];
  const html=`<!doctype html><html><head><meta charset="utf-8"><style>html{background:#fff}body{margin:0;width:720pt;height:405pt;display:flex;font-family:Arial;color:#112a46;background:#fff}.rail{width:16pt;background:#1763bc}.main{margin:32pt 34pt;width:636pt}p{margin:0}h1{font-size:34pt;line-height:1.1;font-weight:700;margin:16pt 0 28pt}.eyebrow{font-size:13pt;color:#1763bc}.row{display:flex;gap:25pt}.label{width:170pt;font-size:22pt;color:#1763bc}.items{width:425pt}ul{font-size:19pt;line-height:1.25;margin:0;padding-left:20pt}li{margin-bottom:12pt}.footer{position:absolute;left:50pt;bottom:22pt;font-size:10pt;color:#53677e}</style></head><body><div class="rail"></div><div class="main"><p class="eyebrow">${eyebrow}</p><h1>${title}</h1><div class="row"><p class="label">${label}</p><div class="items"><ul>${items.map(x=>`<li>${x}</li>`).join('')}</ul></div></div><p class="footer">PROPOSAL DEMO / FICTIONAL DATA &nbsp; 06 NOV 2026 &nbsp; ${i+1} / ${slides.length}</p></div></body></html>`;
  const file=path.join(dir,`slide-${i+1}.html`);fs.writeFileSync(file,html);await html2pptx(file,pptx);
 }
 fs.mkdirSync('docs/training',{recursive:true});await pptx.writeFile({fileName:'docs/training/PoP-Workflow-Training.pptx'});
})().catch(e=>{console.error(e);process.exit(1)});
