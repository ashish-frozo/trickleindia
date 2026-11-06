const fs=require('fs');
const assert=require('assert');
const {chromium}=require('playwright');
(async()=>{
 const browser=await chromium.launch({headless:true,channel:'chrome'});
 try {
  const page=await browser.newPage({viewport:{width:1000,height:1000}});
  const errors=[];page.on('pageerror',e=>errors.push(String(e)));
  // Exercise the truthful missing-voice path deterministically in a real browser.
  await page.addInitScript(()=>{window.speechSynthesis.getVoices=()=>[];});
  await page.goto('http://localhost:8080');
  await page.getByRole('textbox',{name:'Demo access code'}).fill(fs.readFileSync('.local/demo-access-code','utf8').trim());
  await page.getByRole('button',{name:'Open demo',exact:true}).click();
  await page.getByRole('button',{name:'Overview Tab 1 of 6',exact:true}).waitFor();
  await page.evaluate(()=>{location.hash='/help';});
  await page.getByText('Save a contribution',{exact:true}).click();
  await page.getByRole('button',{name:'Listen to instructions',exact:true}).click();
  await page.getByText(/No suitable voice is available/).waitFor();
  await page.screenshot({path:'output/gaps/web-help-missing-voice.png'});
  assert.equal(errors.length,0);
  fs.writeFileSync('docs/evidence/gaps-browser-speech.json',JSON.stringify({errors,missingVoiceHandled:true,realPlaybackVerified:false},null,2));
  console.log('Real browser: help read control, missing-voice recovery, no page errors. Actual audio playback not asserted.');
 } finally {await browser.close();}
})().catch(e=>{console.error(e);process.exit(1)});
