#!/usr/bin/env python3
"""Create local review artifacts, excluding credentials and build/test caches."""
from pathlib import Path
import zipfile,shutil,hashlib,json,subprocess,datetime
root=Path(__file__).resolve().parent.parent;dest=root/'delivery';dest.mkdir(exist_ok=True)
for name in ['PRODUCT.md','DESIGN.md','.impeccable/design.json','docs/design/FINISH_REVIEW.md']:
 assert (root/name).is_file(),f'Missing finished design artifact: {name}'
review=(root/'docs/design/FINISH_REVIEW.md').read_text()
assert 'disposition: ship' in review,'Design review is not ready to ship'
shutil.copy2(root/'apps/mobile/build/app/outputs/flutter-apk/app-profile.apk',dest/'pop-2-demo-arm64.apk')
shutil.copy2(root/'docs/DELIVERY.md',dest/'README.md')
skip={'.local','.git','.gradle','.dart_tool','.idea','.playwright-cli','node_modules','build','dist','__pycache__'}
def archive(output,trees,filter_source=False):
 with zipfile.ZipFile(dest/output,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
  for tree,base in trees:
   paths=[tree] if tree.is_file() else sorted(tree.rglob('*'))
   for p in paths:
    if not p.is_file() or p.is_symlink():continue
    relative=p.relative_to(base)
    if filter_source and (any(part in skip for part in relative.parts) or p.name in {'.env','local.properties','.DS_Store'} or p.suffix in {'.iml','.log','.keystore','.jks'}):continue
    z.write(p,str(relative))
archive('pop-2-web.zip',[(root/'apps/portal/build/web',root/'apps/portal/build/web')])
roots=['PRODUCT.md','DESIGN.md','.impeccable','.dockerignore','.env.example','.flutter-version','.gitignore','.nvmrc','README.md','package.json','package-lock.json','compose.yaml','apps','packages','services','scripts','docs','PoP_2_Demo_Coding_Pack','Trickle_Up_PoP_2_Project_Brief.md','RfpDocuments_6a117cf26110482d92618ed039e0786d.pdf']
archive('pop-2-source.zip',[(root/p,root) for p in roots],True)
archive('pop-2-evidence.zip',[(root/'output',root),(root/'docs/evidence',root)])
secret=(root/'.local/demo-access-code').read_bytes().strip()
for path in dest.iterdir():
 if path.suffix=='.zip':
  with zipfile.ZipFile(path) as z:
   for n in z.namelist():
    assert not any(p in skip for p in Path(n).parts),f'Private/cache path in package: {n}'
    assert Path(n).name!='.env',f'Credential file in package: {n}'
    assert secret not in z.read(n),f'Local secret found in package entry: {n}'
 elif path.suffix=='.apk':
  with zipfile.ZipFile(path) as z:
   assert not any(secret in z.read(n) for n in z.namelist() if not n.endswith('/')),'Local secret embedded in APK'
try: revision=subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True,stderr=subprocess.DEVNULL).strip()
except subprocess.CalledProcessError: revision='uncommitted source'
(dest/'BUILD_INFO.json').write_text(json.dumps({'createdAtUtc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'sourceRevision':revision,'designDisposition':'VengeanceUI Flutter adaptation; locally verified','followUpStatus':'docs/GAP_CLOSURE.md: implemented fixes and open external acceptance','designRequirements':'docs/design/RFP_UI_REQUIREMENTS.md','uiAdaptation':'docs/design/VENGEANCE_UI.md','flutter':'3.47.9','dart':'3.13.7','node':'24.11.1','postgresql':'18.3','android':'API36 AOSP ARM64 emulator; local profile build','remainingAcceptance':['Odia/Ho/Santhali reviewed UI and help translations','Reviewed recorded prompts and voice-assisted navigation','Participant UAT and terminology review','Actual TalkBack speech','Full cached-start target <=2s remains unmet: latest emulator samples 4.099s, 3.163s, 2.640s; physical-device verification required']},indent=2))
files=sorted(p for p in dest.iterdir() if p.is_file() and p.name!='SHA256SUMS')
(dest/'SHA256SUMS').write_text(''.join(f'{hashlib.sha256(p.read_bytes()).hexdigest()}  {p.name}\n' for p in files))
print(json.dumps({p.name:p.stat().st_size for p in files},indent=2))
