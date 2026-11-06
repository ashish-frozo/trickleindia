#!/usr/bin/env python3
"""Explicit synthetic ordinary-APK check. Requires the retained Sakhi demo session.
Posts ONE reviewed ₹200 contribution; never resets device or database.
Run only after confirming the supplied --baseline-paise and an empty outbox.
"""
import sys,re,json,subprocess,argparse
from pathlib import Path
sys.path.insert(0,str(Path(__file__).parent/'android'))
import ui
root=Path(__file__).resolve().parent.parent
parser=argparse.ArgumentParser();parser.add_argument('--baseline-paise',type=int,default=140000);args=parser.parse_args()
baseline_paise=args.baseline_paise
assert baseline_paise>=0 and baseline_paise%100==0
before_label=f'₹{baseline_paise//100:,}';after_label=f'₹{(baseline_paise+20000)//100:,}'

def text(nodes):return '\n'.join(n['content-desc']+' '+n['text'] for n in nodes)
def capture(name):
 nodes=ui.nodes()
 (root/'docs/evidence'/f'nonaws-native-{name}.json').write_text(json.dumps(nodes,ensure_ascii=False,indent=2))
 (root/'output/nonaws'/f'mobile-{name}.png').write_bytes(subprocess.check_output(['adb','-s','emulator-5554','exec-out','screencap','-p']))
 return nodes

def member():
 ui.tap('^Groups');ui.wait_for('^Groups$')
 fields=[n for n in ui.nodes() if 'EditText' in n['class']];assert fields
 b=list(map(int,re.findall(r'\d+',fields[0]['bounds'])))
 ui.adb('shell','input','tap',str((b[0]+b[2])//2),str((b[1]+b[3])//2))
 ui.adb('shell','input','keyevent','123')
 ui.adb('shell','input','keyevent',*(['67']*50))
 ui.adb('shell','input','text','Rani');ui.adb('shell','input','keyevent','4')
 ui.wait_for('Rani Mahto')
 candidates=[n for n in ui.nodes() if 'Rani Mahto' in n['content-desc']]
 assert candidates
 b=list(map(int,re.findall(r'\d+',candidates[0]['bounds'])))
 ui.adb('shell','input','tap',str((b[0]+b[2])//2),str(int(b[1]+(b[3]-b[1])*.78)))
 ui.wait_for('^Record entry$')

ui.tap('^Home');ui.wait_for('Hello, Kavita');assert '0 Waiting to sync' in text(ui.nodes())
member();baseline=capture('baseline');assert before_label in text(baseline)
ui.adb('reverse','--remove','tcp:3000')
# Existing keep-alive sockets can survive reverse removal. End this process
# before entering anything so no established network connection can remain.
ui.adb('shell','am','force-stop','com.frozo.pop_mobile')
ui.adb('shell','am','start','-W','-n','com.frozo.pop_mobile/.MainActivity')
ui.wait_for('Hello, Kavita');member();assert before_label in text(ui.nodes())
ui.tap('^Record entry$');ui.wait_for('^Review$');ui.tap('^₹200$');ui.tap('^Review$');ui.wait_for('^Save contribution$')
capture('review');ui.tap('^Save contribution$');ui.wait_for('Offline.*1 Waiting to sync')
pending=capture('pending');assert before_label in text(pending) and '₹200' in text(pending)
ui.tap('^Sync centre$');ui.wait_for('Savings contribution');before=capture('before-restart')
uuid=r'[a-f0-9]{8}(?:-[a-f0-9]{4}){3}-[a-f0-9]{12}'
ids=re.findall(uuid,text(before));assert len(ids)==1
ui.adb('shell','am','force-stop','com.frozo.pop_mobile')
ui.adb('shell','am','start','-W','-n','com.frozo.pop_mobile/.MainActivity')
ui.wait_for('Hello, Kavita');member();reopen=capture('reopened')
assert before_label in text(reopen) and '₹200' in text(reopen)
ui.tap('^Sync centre$');ui.wait_for('Savings contribution');after=capture('after-restart');assert re.findall(uuid,text(after))==ids
ui.adb('reverse','tcp:3000','tcp:3000');ui.tap('^Retry$');ui.wait_for('Connected.*0 Waiting to sync');member();ui.wait_for(after_label);capture('confirmed')
(root/'docs/evidence/nonaws-native-proof.json').write_text(json.dumps({'operationIds':ids,'sameOperationAcrossRestart':True,'confirmedBeforePaise':baseline_paise,'pendingAfterRestartPaise':20000,'confirmedAfterSyncPaise':baseline_paise+20000,'queueAfterSync':0,'scope':'Ordinary profile APK; synthetic retained demo; no device/data reset'},indent=2))
print('PASS: ordinary APK retained and synchronized the same offline operation across process restart.')
