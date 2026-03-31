#!/bin/bash
# Запуск теста звонков на двух Android эмуляторах параллельно
# Требуется: emulator-5554 и emulator-5556 запущены
#
# Запуск: cd ~/Downloads/taler_id_mobile && bash integration_test/run_call_test.sh

set -e

FLAVOR_ARGS="--flavor dev --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol"

echo "=== Taler ID Call Test (2 emulators) ==="
echo "Emulator 1 (RECEIVER): emulator-5556"
echo "Emulator 2 (CALLER):   emulator-5554"
echo ""

# Start RECEIVER first (it just waits for incoming call)
echo "[1/2] Starting RECEIVER on emulator-5556..."
flutter test integration_test/call_test_receiver.dart $FLAVOR_ARGS -d emulator-5556 &
PID_RECV=$!

# Small delay to let receiver start building
sleep 5

# Start CALLER (it waits 30s after login, then calls)
echo "[2/2] Starting CALLER on emulator-5554..."
flutter test integration_test/call_test_caller.dart $FLAVOR_ARGS -d emulator-5554 &
PID_CALL=$!

echo ""
echo "Waiting for both tests to complete..."
echo "  RECEIVER PID: $PID_RECV"
echo "  CALLER PID:   $PID_CALL"
echo ""

# Wait for both
FAIL=0
wait $PID_RECV || FAIL=1
wait $PID_CALL || FAIL=$((FAIL + 1))

echo ""
if [ $FAIL -eq 0 ]; then
    echo "═══════════════════════════════════════"
    echo "  ✓ Call test PASSED (both sides OK)"
    echo "═══════════════════════════════════════"
else
    echo "═══════════════════════════════════════"
    echo "  ✗ Call test FAILED ($FAIL side(s))"
    echo "═══════════════════════════════════════"
    exit 1
fi
