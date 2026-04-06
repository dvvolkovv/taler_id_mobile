#!/bin/bash
# Запуск теста звонков на двух Android эмуляторах параллельно
# Требуется: emulator-5554 и emulator-5556 запущены
#
# Запуск: cd ~/Downloads/taler_id_mobile && bash integration_test/run_call_test.sh

ADB=~/Library/Android/sdk/platform-tools/adb
FLAVOR_ARGS="--flavor dev --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol"
PKG="tirol.taler.taler_id_mobile.dev"

echo "=== Taler ID Call Test (2 emulators) ==="
echo "Emulator 1 (RECEIVER): emulator-5556"
echo "Emulator 2 (CALLER):   emulator-5554"
echo ""

# Grant microphone permissions
echo "Granting mic permissions..."
$ADB -s emulator-5554 shell pm grant $PKG android.permission.RECORD_AUDIO 2>/dev/null || true
$ADB -s emulator-5556 shell pm grant $PKG android.permission.RECORD_AUDIO 2>/dev/null || true

# Start RECEIVER first (it just waits for incoming call)
echo "[1/2] Starting RECEIVER on emulator-5556..."
flutter test integration_test/call_test_receiver.dart $FLAVOR_ARGS -d emulator-5556 > /tmp/receiver_out.txt 2>&1 &
PID_RECV=$!

# Wait for RECEIVER build to complete before starting CALLER
# (Gradle parallel build causes lock contention)
echo "Waiting 25s for RECEIVER build to complete before starting CALLER..."
sleep 25

# Start CALLER (it waits 30s after login, then calls)
echo "[2/2] Starting CALLER on emulator-5554..."
flutter test integration_test/call_test_caller.dart $FLAVOR_ARGS -d emulator-5554 > /tmp/caller_out.txt 2>&1 &
PID_CALL=$!

echo ""
echo "Both running (RECV=$PID_RECV CALL=$PID_CALL)..."
echo ""

# Wait for both
wait $PID_RECV; RECV=$?
wait $PID_CALL; CALL=$?

echo ""
echo "─────────────────────────────────────"
echo "RECEIVER: $([ $RECV -eq 0 ] && echo '✓ PASSED' || echo '✗ FAILED')"
echo "CALLER:   $([ $CALL -eq 0 ] && echo '✓ PASSED' || echo '✗ FAILED')"
echo "─────────────────────────────────────"

if [ $RECV -ne 0 ]; then
    echo ""
    echo "RECEIVER output (last 30 lines):"
    tail -30 /tmp/receiver_out.txt
fi
if [ $CALL -ne 0 ]; then
    echo ""
    echo "CALLER output (last 30 lines):"
    tail -30 /tmp/caller_out.txt
fi

[ $RECV -eq 0 ] && [ $CALL -eq 0 ] && exit 0 || exit 1
