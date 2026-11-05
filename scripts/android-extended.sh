#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd "$(dirname "$0")/.." && pwd)"
device="${ANDROID_DEVICE:-emulator-5554}"
cd "$project_dir/apps/mobile"
# Run after android-core.sh against its same active dataset.
second_user="$(adb -s "$device" shell pm create-user PoPSecond | sed -n 's/.*id //p' | tr -d '\r')"
test -n "$second_user"
adb -s "$device" shell am start-user -w "$second_user"
adb -s "$device" shell am switch-user "$second_user"
adb -s "$device" reverse tcp:3000 tcp:3000
run_phase() {
  "$project_dir/scripts/flutterw" test --no-uninstall integration_test/core_test.dart -d "$device" --device-user="$1" --dart-define="PHASE=$2" --dart-define=API_URL=http://127.0.0.1:3000 --dart-define-from-file="$project_dir/.local/client-test.json" > "$project_dir/docs/evidence/android-$2.txt" 2>&1
}
run_phase "$second_user" second_device
adb -s "$device" shell am switch-user 0
for phase in registration_save registration_recover_sync lost_ack; do
  if [[ "$phase" == registration_save ]]; then adb -s "$device" reverse --remove tcp:3000; else adb -s "$device" reverse tcp:3000 tcp:3000; fi
  adb -s "$device" shell am force-stop --user 0 com.frozo.pop_mobile
  run_phase 0 "$phase"
done
