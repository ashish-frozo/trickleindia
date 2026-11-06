// Build an editable, high-contrast field-training deck from HTML slides.
// Run with NODE_PATH containing pptxgenjs/playwright/sharp and HTML2PPTX set.
const fs = require('fs'), path = require('path');
const PptxGenJS = require('pptxgenjs');
const html2pptx = require(process.env.HTML2PPTX);

const slides = [
  ['Start here', 'A simple day.\nA reliable record.', 'Field workflow practice', [
    'Work offline when the signal drops', 'Save each action once', 'Sync when the connection returns', 'Check the confirmed result'],
    'LEARN  /  SAVE  /  SYNC  /  VERIFY', 'A local demo using fictional participant data.'],
  ['01  Capture', 'Record the contribution', 'Sakhi practice', [
    'Open the right member and group', 'Enter amount, date and contribution type', 'Review the details before saving', 'Check that the item says Pending'],
    'Save once', 'Pending work stays separate from confirmed savings.'],
  ['02  Recover', 'Keep the same saved action', 'If the app closes', [
    'Reopen the app after a restart', 'Find the saved item in Pending', 'Retry that item when online', 'Wait for a confirmed receipt'],
    'Same action', 'A retry uses the original operation ID.'],
  ['03  Confirm', 'Read the final result', 'Member passbook', [
    'Check the confirmed savings balance', 'Check the receipt for the contribution', 'Confirm Pending is empty after sync', 'Ask a manager to review any mismatch'],
    'One posting', 'In the verified demo, one ₹200 offline item posted once.'],
  ['04  Review', 'Use the portal for oversight', 'Manager practice', [
    'Choose a scoped programme report', 'Check filters and snapshot time', 'Export the full filtered result to CSV', 'Review imports before committing them'],
    'Trace totals', 'The demo has five scoped snapshot reports.'],
  ['05  Resolve', 'Correct records with care', 'When something is wrong', [
    'Retry the same operation after a temporary error', 'Review a conflict against the latest value', 'Use a reversal for a confirmed correction', 'Never create a second payment to replace a retry'],
    'Keep history', 'Confirmed financial corrections preserve the original entry.'],
  ['06  Get help', 'Choose what to open', 'Cited help and voice', [
    'Type a screen name or use microphone consent', 'Review recognized text before opening a screen', 'Open help instructions with their source', 'Payments still use the normal review form'],
    'Review first', 'Voice services and language coverage vary by device.'],
  ['07  Acceptance', 'Know what this demo proves', 'Evidence and next steps', [
    'Local tests cover API, offline and workflow rules', 'The training data is synthetic', 'AWS, live identity and field UAT need customer setup', 'Five-language and physical-device acceptance remain'],
    'Demo status', 'Local engineering evidence is not production acceptance.'],
];

const esc = s => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
const makeSlide = (slide, i) => {
  const [eyebrow, title, label, items, callout, note] = slide;
  if (i === 0) return `<!doctype html><html><head><meta charset="utf-8"><style>
    *{box-sizing:border-box}html,body{margin:0;width:720pt;height:405pt;font-family:Arial;background:#10243a;color:#fff}
    .canvas{height:405pt;padding:36pt 43pt;position:relative;overflow:hidden}.orb{position:absolute;width:270pt;height:270pt;border-radius:50%;background:#183a5d;right:-42pt;top:45pt}
    .orb2{position:absolute;width:144pt;height:144pt;border-radius:50%;background:#b8e2d0;right:27pt;top:107pt}.brand{font-size:12pt;font-weight:bold;letter-spacing:1pt;color:#b8e2d0}
    .eyebrow{margin-top:58pt;color:#9bb8d8;font-size:13pt}h1{font-size:43pt;line-height:1.05;margin:16pt 0 12pt;width:420pt;white-space:pre-line;position:relative}
    .sub{font-size:19pt;color:#d8e3ef;margin:0}.rule{margin-top:34pt;width:77pt;height:4pt;background:#ed987c}.tags{display:flex;gap:9pt;margin-top:17pt}.tag{font-size:10pt;color:#10243a;background:#b8e2d0;border-radius:12pt;padding:7pt 11pt;font-weight:bold}
    .foot{position:absolute;left:43pt;bottom:22pt;color:#91a9c3;font-size:9pt;letter-spacing:.7pt}
  </style></head><body><div class="canvas"><div class="orb"></div><div class="orb2"></div><p class="brand">PoP 2.0&nbsp; / &nbsp;FIELD GUIDE</p><p class="eyebrow">${esc(eyebrow)}</p><h1>${esc(title)}</h1><p class="sub">${esc(label)}</p><div class="rule"></div><div class="tags">${items.map(x=>`<span class="tag">${esc(x)}</span>`).join('')}</div><p class="foot">LOCAL TRAINING DEMO&nbsp; · &nbsp;FICTIONAL DATA&nbsp; · &nbsp;06 NOV 2026</p></div></body></html>`;
  const nav = slides.slice(1).map((s, n) => `<div class="nav ${n + 1 === i ? 'active' : ''}"><b>${String(n + 1).padStart(2, '0')}</b><span>${esc(s[0].replace(/^\d+\s+/, ''))}</span></div>`).join('');
  return `<!doctype html><html><head><meta charset="utf-8"><style>
    *{box-sizing:border-box}html,body{margin:0;width:720pt;height:405pt;font-family:Arial;color:#152b43;background:#f4f6fa}
    .layout{height:405pt;display:flex}.rail{width:158pt;background-color:#10243a;padding:25pt 15pt;color:#fff;flex:none;border-right:3pt solid #245eeb}.brand{font-size:10pt;font-weight:bold;letter-spacing:.7pt;color:#b8e2d0;margin:0 0 27pt}.rail-title{font-size:9pt;color:#9bb0c6;margin:0 0 10pt;text-transform:uppercase;letter-spacing:1pt}.nav{display:flex;align-items:center;gap:9pt;height:34pt;color:#aebed0;font-size:10pt}.nav b{width:22pt;height:22pt;border:1pt solid #526a82;border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:8pt}.nav.active{color:#fff;font-weight:bold}.nav.active b{background-color:#b8e2d0;color:#10243a;border-color:#b8e2d0}.rail-note{position:absolute;left:16pt;bottom:20pt;color:#8197ad;font-size:8pt}
    .main{padding:24pt 27pt 20pt;width:562pt;position:relative}.top{display:flex;justify-content:space-between;align-items:center}.eyebrow{margin:0;color:#245eeb;font-size:10pt;font-weight:bold}.pill{background:#e5ecff;color:#2452b5;padding:6pt 10pt;border-radius:12pt;font-size:9pt;font-weight:bold}
    h1{font-size:26pt;line-height:1.05;margin:15pt 0 6pt;color:#132b46}.sub{margin:0;color:#60748a;font-size:12pt}.content{display:flex;gap:13pt;margin-top:20pt;height:237pt}.steps{width:345pt;display:flex;flex-direction:column;gap:8pt}.step{min-height:50pt;display:flex;align-items:center;background:#fff;border:1pt solid #e0e6ee;border-radius:10pt;padding:8pt 10pt;box-shadow:0 2pt 5pt rgba(22,43,67,.04)}.dot{width:25pt;height:25pt;border-radius:8pt;background:#e6f4ed;color:#186b4b;font-weight:bold;font-size:10pt;display:flex;align-items:center;justify-content:center;flex:none;margin-right:9pt}.step p{font-size:12pt;line-height:1.12;margin:0;color:#263d55}
    .focus{width:148pt;background-color:#e5ecff;border:1pt solid #b9caef;border-left:4pt solid #245eeb;border-radius:13pt;padding:14pt 13pt;color:#152b43;position:relative;overflow:hidden}.focus:after{content:'';position:absolute;width:100pt;height:100pt;border-radius:50%;background-color:#b8e2d0;right:-43pt;bottom:-39pt;opacity:.65}.focus-kicker{font-size:9pt;letter-spacing:.8pt;color:#186b4b;margin:0;text-transform:uppercase}.focus h2{font-size:24pt;line-height:1.04;margin:17pt 0 12pt;position:relative;z-index:1;color:#183a5d}.focus p.note{font-size:11pt;line-height:1.22;color:#263d55;margin:0;position:relative;z-index:1}.badge{position:absolute;left:13pt;bottom:14pt;border-radius:10pt;background-color:#b8e2d0;color:#12334d;padding:6pt 8pt;font-size:8pt;font-weight:bold;z-index:2}
    .footer{position:absolute;left:27pt;bottom:9pt;color:#77899b;font-size:8pt;letter-spacing:.4pt}.page{position:absolute;right:27pt;bottom:8pt;color:#77899b;font-size:9pt}
  </style></head><body><div class="layout"><div class="rail"><p class="brand">PoP 2.0&nbsp; / &nbsp;FIELD GUIDE</p><p class="rail-title">Practice path</p>${nav}<p class="rail-note">LOCAL DEMO · FICTIONAL DATA</p></div><main class="main"><div class="top"><p class="eyebrow">${esc(eyebrow)}</p><span class="pill">${String(i).padStart(2, '0')} / ${String(slides.length - 1).padStart(2, '0')}</span></div><h1>${esc(title)}</h1><p class="sub">${esc(label)}</p><div class="content"><div class="steps">${items.map((x, n) => `<div class="step"><span class="dot">${n + 1}</span><p>${esc(x)}</p></div>`).join('')}</div><div class="focus"><p class="focus-kicker">Remember</p><h2>${esc(callout)}</h2><p class="note">${esc(note)}</p><span class="badge">TRAINING ONLY</span></div></div><p class="footer">SYNTHETIC DATA&nbsp; · &nbsp;LOCAL PROPOSAL DEMO&nbsp; · &nbsp;06 NOV 2026</p><p class="page">${i + 1} / ${slides.length}</p></main></div></body></html>`;
};

(async () => {
  const dir = path.resolve('.local/training-slides'); fs.mkdirSync(dir, { recursive: true });
  const pptx = new PptxGenJS(); pptx.layout = 'LAYOUT_16x9'; pptx.author = 'PoP project';
  pptx.subject = 'Local proposal and field workflow training'; pptx.title = 'PoP 2.0 — field workflow guide';
  for (let i = 0; i < slides.length; i++) {
    const file = path.join(dir, `slide-${i + 1}.html`); fs.writeFileSync(file, makeSlide(slides[i], i));
    await html2pptx(file, pptx);
  }
  fs.mkdirSync('docs/training', { recursive: true });
  await pptx.writeFile({ fileName: 'docs/training/PoP-Workflow-Training.pptx' });
})().catch(e => { console.error(e); process.exit(1); });
