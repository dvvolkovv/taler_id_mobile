#!/bin/bash
# Group mesh voice room — 2-emulator orchestrator.
#
# Runs the host-side integration test on emulator-5554 while emulator-5556
# acts as the invitee. The Flutter integration_test harness cannot reliably
# tap a native incoming-call overlay (flutter_callkit_incoming), so the
# invitee Accept step must be performed by a human (or via separate adb-input
# scripting added in a later phase).
#
# Prerequisites (see CLAUDE.md §3 for full setup):
#   - Two emulators booted:
#       Pixel_XL_API_33   → emulator-5554 (host / caller)
#       Pixel_XL_2_API_33 → emulator-5556 (invitee / receiver)
#   - RECORD_AUDIO granted on both (script does this automatically)
#   - Both apps installed with tirol.taler.taler_id_mobile.dev bundle ID
#   - emulator-5554 logged in as integration_test@taler-test.com
#   - emulator-5556 logged in as integration_test_2@taler-test.com
#   - Both test accounts are contacts with each other on DEV
#     (conversation ID: 91f97844-307b-4a20-ad62-c1d2820e627f)
#
# Usage:
#   cd ~/Downloads/taler_id_mobile
#   bash integration_test/run_group_mesh_call_test.sh

set -e

ADB=~/Library/Android/sdk/platform-tools/adb
HOST=emulator-5554
INVITEE=emulator-5556
PKG="tirol.taler.taler_id_mobile.dev"
FLAVOR_ARGS="--flavor dev --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol"

echo "=== Taler ID — Group Mesh Voice Room Integration Test ==="
echo "  Host (caller):   $HOST"
echo "  Invitee:         $INVITEE"
echo ""

# ── Verify both emulators are reachable ──────────────────────────────────────
echo "[1/4] Verifying emulators..."
$ADB devices | grep -E "$HOST|$INVITEE" || {
  echo "ERROR: Both emulators must be booted ($HOST, $INVITEE)."
  echo "  flutter emulators --launch Pixel_XL_API_33"
  echo "  ~/Library/Android/sdk/emulator/emulator -avd Pixel_XL_2_API_33 -port 5556 -read-only &"
  echo "  # Wait ~20 s, then re-run this script."
  exit 1
}

# ── Grant RECORD_AUDIO ────────────────────────────────────────────────────────
echo "[2/4] Granting RECORD_AUDIO on both emulators..."
$ADB -s $HOST    shell pm grant $PKG android.permission.RECORD_AUDIO 2>/dev/null || true
$ADB -s $INVITEE shell pm grant $PKG android.permission.RECORD_AUDIO 2>/dev/null || true

# ── Launch invitee app in the background ─────────────────────────────────────
echo "[3/4] Launching invitee app on $INVITEE..."
flutter run \
  $FLAVOR_ARGS \
  -t lib/main_dev.dart \
  -d $INVITEE \
  > /tmp/gmc_invitee_out.txt 2>&1 &
INVITEE_PID=$!

echo "      Invitee flutter run PID=$INVITEE_PID"
echo "      Waiting 25 s for invitee build + app settle..."
sleep 25

# ── Run host integration test ─────────────────────────────────────────────────
echo "[4/4] Running host integration test on $HOST..."
flutter test \
  $FLAVOR_ARGS \
  -t lib/main_dev.dart \
  -d $HOST \
  integration_test/group_mesh_call_test.dart \
  > /tmp/gmc_host_out.txt 2>&1
HOST_RC=$?

# ── Collect results ───────────────────────────────────────────────────────────
echo ""
echo "─────────────────────────────────────────────────────"
echo "HOST test: $([ $HOST_RC -eq 0 ] && echo 'PASSED' || echo 'FAILED') (exit $HOST_RC)"
echo "─────────────────────────────────────────────────────"

if [ $HOST_RC -ne 0 ]; then
  echo ""
  echo "Host output (last 40 lines):"
  tail -40 /tmp/gmc_host_out.txt
fi

# ── Stop invitee ──────────────────────────────────────────────────────────────
echo ""
echo "Stopping invitee (PID=$INVITEE_PID)..."
kill $INVITEE_PID 2>/dev/null || true

# ── Manual step guidance ──────────────────────────────────────────────────────
echo ""
echo "────────────────────────────────────────────────────────────────"
echo "MANUAL STEP — Invitee Accept (cross-device portion):"
echo ""
echo "  While the host integration test is in the LOBBY state"
echo "  (test log shows '[GMC-TEST] Lobby screen reached'), the invitee"
echo "  device ($INVITEE / integration_test_2@taler-test.com) will display"
echo "  an incoming group call notification/overlay."
echo ""
echo "  Tap ACCEPT on $INVITEE to trigger the GMCActive transition on the host."
echo "  Expected host flow:"
echo "    GMCLobby → (invitee joins) → GMCActive → /group-call/:id (active screen)"
echo ""
echo "  Cross-device automation of Accept is tracked separately."
echo "  For now, verify the active screen renders on both devices manually."
echo "────────────────────────────────────────────────────────────────"
echo ""
echo "Invitee log: /tmp/gmc_invitee_out.txt"
echo "Host log:    /tmp/gmc_host_out.txt"

exit $HOST_RC
