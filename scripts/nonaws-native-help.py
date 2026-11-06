#!/usr/bin/env python3
"""Read-only native help, consent and persisted-language acceptance smoke check."""
import sys,json,re,subprocess
from pathlib import Path
sys.path.insert(0,str(Path(__file__).parent/'android'))
import ui
root=Path(__file__).resolve().parent.parent

def capture(name):
 nodes=ui.nodes()
 (root/'docs/evidence'/f'nonaws-native-{name}.json').write_text(json.dumps(nodes,ensure_ascii=False,indent=2))
 (root/'output/nonaws'/f'mobile-{name}.png').write_bytes(subprocess.check_output(['adb','-s','emulator-5554','exec-out','screencap','-p']))
 return nodes

def reveal(pattern):
 for _ in range(6):
  if any(re.search(pattern,n['content-desc']+' '+n['text']) for n in ui.nodes()):return
  ui.adb('shell','input','swipe','700','1750','700','850','350')
 raise RuntimeError('Missing visible help control: '+pattern)

ui.tap('^Home');ui.wait_for('Hello, Kavita');capture('home-en')
ui.tap('^Help');ui.wait_for('Help and voice navigation');ui.tap('Help and voice navigation')
ui.wait_for('Open a screen by voice');capture('assistant-en');reveal('^Use microphone')
ui.tap('^Use microphone');ui.wait_for('Use short screen names only');capture('microphone-consent');ui.tap('^Cancel$')
ui.tap('हिन्दी');ui.wait_for('English');capture('assistant-hi')
ui.adb('shell','am','force-stop','com.frozo.pop_mobile')
ui.adb('shell','am','start','-W','-n','com.frozo.pop_mobile/.MainActivity')
ui.wait_for('English');capture('home-hi-reopened')
ui.tap('English');ui.wait_for('हिन्दी');capture('home-en')
(root/'docs/evidence/nonaws-native-help-proof.json').write_text(json.dumps({'helpAndVoiceScreenOpened':True,'microphoneConsentShownAndCancelled':True,'hindiPreferenceSurvivedProcessRestart':True,'restoredEnglish':True,'actualRecognitionOrSpokenOutputVerified':False},indent=2))
print('PASS: native help, microphone consent and language preference across process restart.')
