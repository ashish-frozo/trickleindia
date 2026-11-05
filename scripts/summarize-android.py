#!/usr/bin/env python3
"""Summarise recorded test results without manufacturing acceptance results."""
import json,pathlib,re
root=pathlib.Path(__file__).resolve().parent.parent
phases=['bootstrap','save_offline','recover_offline','sync','second_device','registration_save','registration_recover_sync','lost_ack']
results=[]
for phase in phases:
 text=(root/'docs/evidence'/f'android-{phase}.txt').read_text()
 assert 'All tests passed!' in text, f'{phase} did not pass'
 results.append({'phase':phase,'passed':True,'encryptedCacheInitMs':[int(x) for x in re.findall(r'CACHE_START_MS=(\d+)',text)],'localSaveMs':[int(x) for x in re.findall(r'LOCAL_SAVE_MS=(\d+)',text)]})
report={'device':'Android API 36 AOSP ARM64 emulator, software graphics, two cores, 2.5 GB RAM','scope':'Cache init timing excludes OS/engine startup. Save timing measures durable enqueue, not network acceptance. Observations are not performance guarantees.','results':results}
(root/'docs/evidence/android-summary.json').write_text(json.dumps(report,indent=2))
print('Eight recorded Android phases passed; timing samples extracted from actual logs.')
