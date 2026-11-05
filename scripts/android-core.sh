#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd "$(dirname "$0")/.." && pwd)"
flutter_bin="${FLUTTER_BIN:-$project_dir/.local/flutter/bin/flutter}"
device="${ANDROID_DEVICE:-emulator-5554}"
cd "$project_dir/apps/mobile"
adb -s "$device" shell pm clear com.frozo.pop_mobile || true
for phase in bootstrap save_offline recover_offline sync; do
  if [[ "$phase" == bootstrap || "$phase" == sync ]]; then
    adb -s "$device" reverse tcp:3000 tcp:3000
  else
    adb -s "$device" reverse --remove tcp:3000 || true
  fi
  adb -s "$device" shell am force-stop com.frozo.pop_mobile || true
  "$flutter_bin" test --no-uninstall integration_test/core_test.dart -d "$device" \
    --dart-define="PHASE=$phase" \
    --dart-define=API_URL=http://127.0.0.1:3000 \
    --dart-define-from-file="$project_dir/.local/client-test.json" \
    > "$project_dir/docs/evidence/android-$phase.txt" 2>&1
 done
python3 - "$project_dir" <<'PY'
import json,pathlib,sys
root=pathlib.Path(sys.argv[1])
def operation(phase):
 line=next(line for line in (root/'docs/evidence'/f'android-{phase}.txt').read_text().splitlines() if 'DURABLE_ENVELOPE=' in line)
 value=json.loads(line.split('DURABLE_ENVELOPE=',1)[1])
 return {key:value[key] for key in ['datasetId','operationId','kind','clientCreatedAt','payload','payloadHash','actorId','subjectId','localSequence']}
a,b=operation('save_offline'),operation('recover_offline')
assert a==b, 'Frozen operation changed across Android process termination'
(root/'docs/evidence/android-durability.json').write_text(json.dumps({'identicalAcrossForceStop':True,'operation':a},indent=2))
print('Identical operation, transaction, payload and hash recovered after force-stop')
PY
