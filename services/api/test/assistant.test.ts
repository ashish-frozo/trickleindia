import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {answerHelp,assistantQuestion,localCards} from '../src/assistant.js';
const pack=JSON.parse(await readFile(new URL('../../../packages/ui/assets/content_cards.json',import.meta.url),'utf8'));
const provider={endpoint:'https://api.example.invalid/chat/completions',apiKey:'test-only-key',model:'test-model',timeoutMs:100};
test('local help cites canonical instructions and unsupported questions stay unsupported',async()=>{
 assert.equal(localCards(pack,'How do I save savings?','en')[0].id,'save-contribution');
 assert.equal((await answerHelp(pack,{question:'मुझे बचत जमा करनी है',language:'hi',remoteConsent:false})).citations[0].id,'save-contribution');
 const unsupported=await answerHelp(pack,{question:'Tell me the weather',language:'en',remoteConsent:false});assert.equal(unsupported.supported,false);
 assert.equal(assistantQuestion.safeParse({question:'help',language:'xx',execute:true}).success,false);
});
test('provider requires explicit per-request consent and never returns model prose',async()=>{
 let calls=0;const transport=(async(_url:any,options:any)=>{calls++;const request=JSON.parse(options.body);assert.equal(request.store,false);assert.equal(request.messages.length,2);return new Response(JSON.stringify({choices:[{message:{content:JSON.stringify({cardIds:['save-contribution']})}}]}));}) as typeof fetch;
 await answerHelp(pack,{question:'help me',language:'en',remoteConsent:false},provider,transport);assert.equal(calls,0);
 const answer=await answerHelp(pack,{question:'help me',language:'en',remoteConsent:true},provider,transport);assert.equal(calls,1);assert.equal(answer.mode,'provider');assert.deepEqual(answer.citations[0].steps,pack.cards[0].locales.en.steps);
});
test('invalid citations, oversized output, HTTP failure and timeout fall back without mutation',async()=>{
 for(const transport of [async()=>new Response(JSON.stringify({choices:[{message:{content:'{"cardIds":["invented"]}'}}]})),async()=>new Response('x'.repeat(40000)),async()=>new Response('',{status:429}),async()=>{throw new Error('Timeout');}]){
  const answer=await answerHelp(pack,{question:'save savings',language:'en',remoteConsent:true},provider,transport as typeof fetch);assert.equal(answer.mode,'fallback');assert.equal(answer.citations[0].id,'save-contribution');
 }
});
test('unsafe endpoint is rejected before sending any request',async()=>{
 let called=false;const answer=await answerHelp(pack,{question:'savings',language:'en',remoteConsent:true},{...provider,endpoint:'http://localhost:3000'},(async()=>{called=true;return new Response();}) as typeof fetch);assert.equal(called,false);assert.equal(answer.mode,'fallback');
});
