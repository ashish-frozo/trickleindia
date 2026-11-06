#!/usr/bin/env python3
"""Measure cached activity starts; does not count splash-only timing as field acceptance."""
import argparse,json,re,subprocess,time
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--serial',default='emulator-5554');p.add_argument('--samples',type=int,default=5);p.add_argument('--output',type=Path,required=True);a=p.parse_args()
assert 1 <= a.samples <= 20
adb='/Users/ashishdhiman/Library/Android/sdk/platform-tools/adb'
if not Path(adb).exists(): adb='adb'
def run(*args):return subprocess.check_output([adb,'-s',a.serial,*args],text=True)
assert run('shell','getprop','sys.boot_completed').strip()=='1','Wait for Android to boot'
package='com.frozo.pop_mobile';samples=[]
for i in range(a.samples):
 run('shell','am','force-stop',package)
 raw=run('shell','am','start','-W','-n',package+'/.MainActivity')
 timings={k:int(v) for k,v in re.findall(r'(TotalTime|ThisTime|WaitTime):\s*(\d+)',raw)}
 samples.append({'sample':i+1,'timingsMs':timings,'output':raw})
 time.sleep(3)
a.output.parent.mkdir(parents=True,exist_ok=True)
a.output.write_text(json.dumps({'device':a.serial,'samples':samples,'scope':'Android activity launch timing; verify cached content visibility separately. Emulator results do not establish field-device acceptance.','targetMs':2000},indent=2))
print(json.dumps(samples,indent=2))
