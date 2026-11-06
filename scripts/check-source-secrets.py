#!/usr/bin/env python3
"""Check tracked text and paths without printing matched secrets. Not a pentest."""
from pathlib import Path
import re, subprocess
root=Path(__file__).resolve().parent.parent
patterns=[re.compile(rb'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----'),re.compile(rb'\bAKIA[0-9A-Z]{16}\b'),re.compile(rb'\bgh[pousr]_[A-Za-z0-9]{30,}\b')]
violations=[]
for name in subprocess.check_output(['git','ls-files','-z'],cwd=root).decode().split('\0'):
 if not name: continue
 path=root/name
 if not path.is_file():continue
 if path.name in {'.env','key.properties','local.properties'} or path.suffix in {'.jks','.keystore','.dump'}:
  violations.append(name+' (private file)');continue
 if path.stat().st_size>2_000_000:continue
 data=path.read_bytes()
 if b'\0' in data:continue
 if any(pattern.search(data) for pattern in patterns):violations.append(name+' (credential pattern)')
if violations:raise SystemExit('Sensitive material detected in: '+', '.join(violations))
print('Tracked source checks passed; no private configuration or recognised credential patterns found.')
