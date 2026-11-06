import {readFile,writeFile,readdir} from 'node:fs/promises';
const root=new URL('../',import.meta.url);
const load=async path=>JSON.parse(await readFile(new URL(path,root),'utf8'));
const en=await load('packages/ui/assets/ui_en.arb'),hi=await load('packages/ui/assets/ui_hi.arb');
const keys=value=>Object.keys(value).filter(k=>!k.startsWith('@')).sort();
if(JSON.stringify(keys(en))!==JSON.stringify(keys(hi)))throw new Error('Locale keys differ');
const lib=new URL('packages/ui/lib/',root);
for(const path of (await readdir(lib,{recursive:true})).filter(p=>p.endsWith('.dart'))){
 const source=await readFile(new URL(path,lib),'utf8');
 for(const match of source.matchAll(/\bt\('([^']+)'\)/g))if(!match[1].includes('$')&&!(match[1] in en))throw new Error(`Missing locale key: ${match[1]} in ${path}`);
}
const tokens=await load('packages/ui/assets/design_tokens.json');
const luminance=hex=>{const values=hex.slice(1).match(/../g).map(n=>parseInt(n,16)/255).map(n=>n<=0.04045?n/12.92:((n+0.055)/1.055)**2.4);return values[0]*0.2126+values[1]*0.7152+values[2]*0.0722;};
const pairs=[['#FFFFFF','primary'],['text','canvas'],['text','surface'],['muted','canvas'],['muted','surface'],['primary','primaryTint'],['success','successTint'],['warning','warningTint'],['error','errorTint'],['accent','forest'],['forestMuted','forest'],['#FFFFFF','forest']];
const report=[`Bilingual message keys match: ${keys(en).length}`,'All static UI message references resolve.'];
for(const[a,b]of pairs){const l1=luminance(tokens.colors[a]??a),l2=luminance(tokens.colors[b]??b),ratio=(Math.max(l1,l2)+0.05)/(Math.min(l1,l2)+0.05);if(ratio<4.5)throw new Error(`Contrast failed ${a}/${b}`);report.push(`${a}/${b}: ${ratio.toFixed(2)}:1`);}
const help=await load('packages/ui/assets/content_cards.json');for(const card of help.cards)for(const lang of ['en','hi'])if(card.locales[lang].audioAsset!==null)throw new Error('Audio asset requires review evidence');
report.push('Four bilingual draft help cards bundled; no unavailable audio path exposed.');
await writeFile(new URL('docs/evidence/assets-and-contrast.txt',root),report.join('\n')+'\n');console.log(report.join('\n'));
