#!/usr/bin/env python3
"""Export complete translation worksheets; validate reviewed imports without silent fallback."""
import argparse,csv,json
from pathlib import Path
root=Path(__file__).resolve().parent.parent
parser=argparse.ArgumentParser()
parser.add_argument('action',choices=['export','validate'])
parser.add_argument('--language',choices=['or','hoc','sat'],required=True)
parser.add_argument('--file',type=Path,required=True)
a=parser.parse_args()
en=json.loads((root/'packages/ui/assets/ui_en.arb').read_text())
cards=json.loads((root/'packages/ui/assets/content_cards.json').read_text())
source={f'ui.{k}':v for k,v in en.items() if not k.startswith('@')}
for card in cards['cards']:
 for key in ['title','audioScript']:
  source[f"help.{card['id']}.{key}"]=card['locales']['en'][key]
 for i,step in enumerate(card['locales']['en']['steps']):
  source[f"help.{card['id']}.steps.{i}"]=step
fields=['key','source','translation','reviewer','status']
if a.action=='export':
 a.file.parent.mkdir(parents=True,exist_ok=True)
 with a.file.open('w',newline='') as f:
  w=csv.DictWriter(f,fieldnames=fields,lineterminator='\n');w.writeheader()
  w.writerows(dict(key=k,source=v,translation='',reviewer='',status='needs-translation') for k,v in source.items())
 print(f'Exported {len(source)} entries for {a.language}: {a.file}')
else:
 with a.file.open(newline='') as f: rows=list(csv.DictReader(f))
 assert len({x['key'] for x in rows})==len(rows),'Duplicate keys'
 assert {x['key'] for x in rows}==set(source),'Missing or unexpected keys'
 for x in rows:
  assert x['source']==source[x['key']],f"Stale source: {x['key']}"
  assert x['translation'].strip() and x['reviewer'].strip() and x['status']=='reviewed',f"Not reviewed: {x['key']}"
 print(f'All {len(rows)} translations reviewed; script rendering and participant testing still required.')
