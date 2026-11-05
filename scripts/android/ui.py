#!/usr/bin/env python3
"""Read-only UI inventory plus explicit input actions for the demo test device."""
import argparse,json,re,subprocess,os,time,xml.etree.ElementTree as ET

def adb(*args):
 return subprocess.check_output(['adb','-s',os.environ.get('ANDROID_DEVICE','emulator-5554'),*args],text=True,stderr=subprocess.DEVNULL)
def nodes():
 adb('shell','uiautomator','dump','/sdcard/pop-window.xml')
 tree=ET.fromstring(adb('shell','cat','/sdcard/pop-window.xml'))
 result=[]
 for node in tree.iter('node'):
  attrs=node.attrib
  if not(attrs.get('text') or attrs.get('content-desc') or attrs.get('clickable')=='true' or 'EditText' in attrs.get('class','')):continue
  result.append({key:attrs.get(key,'') for key in ['text','content-desc','class','clickable','password','focused','selected','bounds']})
 return result

def tap(pattern):
 candidates=[n for n in nodes() if re.search(pattern,(n['text']+' '+n['content-desc']).strip(),re.I)]
 if not candidates:raise RuntimeError('UI target not found: '+pattern)
 candidates.sort(key=lambda n:n['clickable']!='true')
 bounds=list(map(int,re.findall(r'\d+',candidates[0]['bounds'])))
 if len(bounds)!=4:raise RuntimeError('Invalid target bounds')
 adb('shell','input','tap',str((bounds[0]+bounds[2])//2),str((bounds[1]+bounds[3])//2))

def wait_for(pattern, timeout=30):
 deadline=time.monotonic()+timeout
 while time.monotonic()<deadline:
  result=nodes()
  if any(re.search(pattern,(n['text']+' '+n['content-desc']).strip(),re.I) for n in result):return result
 raise RuntimeError('UI state did not arrive: '+pattern)

if __name__=='__main__':
 parser=argparse.ArgumentParser();parser.add_argument('action',choices=['list','tap','wait']);parser.add_argument('pattern',nargs='?');args=parser.parse_args()
 if args.action=='tap':tap(args.pattern)
 elif args.action=='wait':wait_for(args.pattern)
 else:
  output=nodes()
  for node in output:
   if node['password']=='true':node['text']='[password hidden]'
  print(json.dumps(output,ensure_ascii=False,indent=2))
