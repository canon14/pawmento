#!/usr/bin/env bash
# PawMento test runner — tiered for speed.
#
# Usage:
#   ./Scripts/run-tests.sh smoke     # ~20s — uses connected iPhone if available
#   ./Scripts/run-tests.sh full      # ~3–5m — all unit tests, no rebuild
#   ./Scripts/run-tests.sh build     # compile app + tests only
#   ./Scripts/run-tests.sh all       # build + full suite (CI / pre-push)
#
# Destination (default: connected physical iPhone, no simulator runtime needed):
#   PAWMENTO_DEVICE_ID=<udid>   Force a specific device
#   PAWMENTO_USE_SIMULATOR=1      Use simulator instead (requires iOS Simulator runtime)
#   PAWMENTO_SIMULATOR_ID=<id>  Simulator UDID when PAWMENTO_USE_SIMULATOR=1
#
# Physical device requirements:
#   - iPhone unlocked, trusted, Developer Mode on
#   - Xcode → Settings → Components → iOS <version> platform installed
#     (device platform only — NOT the iOS Simulator runtime)

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCHEME="PawMento"

resolve_physical_device_id() {
  local line udid
  line="$(xcrun xctrace list devices 2>/dev/null \
    | grep -E 'iPhone|iPad' \
    | grep -v Simulator \
    | grep -v 'MacBook' \
    | head -1 || true)"
  if [[ -z "$line" ]]; then
    return 1
  fi
  udid="$(sed -E 's/.*\(([0-9A-Fa-f-]{25,})\)$/\1/' <<<"$line")"
  if [[ -z "$udid" ]]; then
    return 1
  fi
  echo "$udid"
}

resolve_destination() {
  if [[ "${PAWMENTO_USE_SIMULATOR:-0}" == "1" ]]; then
    local sim_id="${PAWMENTO_SIMULATOR_ID:-C5B06961-D137-4318-B2A7-3164953BA621}"
    DESTINATION="platform=iOS Simulator,id=${sim_id}"
    DESTINATION_KIND="simulator"
    echo "→ Using iOS Simulator (${sim_id})"
    return
  fi

  local device_id="${PAWMENTO_DEVICE_ID:-}"
  if [[ -z "$device_id" ]]; then
    device_id="$(resolve_physical_device_id || true)"
  fi

  if [[ -n "$device_id" ]]; then
    DESTINATION="platform=iOS,id=${device_id}"
    DESTINATION_KIND="device"
    echo "→ Using connected iPhone/iPad (${device_id})"
    return
  fi

  echo "No connected iOS device found." >&2
  echo "Connect and unlock your iPhone, or set PAWMENTO_USE_SIMULATOR=1 to use a simulator." >&2
  exit 1
}

COMMON_FLAGS=(
  -scheme "$SCHEME"
  -parallel-testing-enabled NO
  -quiet
)

# Fast pure-logic tests — expand when adding new focused unit suites.
SMOKE_TESTS=(
  PawMentoTests/SubscriptionEntitlementTests
  PawMentoTests/SubscriptionProductIDsTests
  PawMentoTests/AICoachClientStreamRetryTests
  PawMentoTests/CoachViewModelSendGuardTests
  PawMentoTests/CoachViewModelMessagePersistenceTests
  PawMentoTests/CoachViewModelSubscriptionFetchTests
  PawMentoTests/LogCategoryStoredValueTests
  PawMentoTests/StorageManagerPathTests
  PawMentoTests/AuthManagerProfileTests
  PawMentoTests/InsightCalendarTests
  PawMentoTests/ReminderLogSourceKeyTests
  PawMentoTests/CorrelationDetectorTests
  PawMentoTests/TemporalDetectorTests
  PawMentoTests/TrendDetectorTests
)

prepare_destination() {
  if [[ "${DESTINATION_KIND}" == "simulator" ]]; then
    local sim_id="${PAWMENTO_SIMULATOR_ID:-C5B06961-D137-4318-B2A7-3164953BA621}"
    xcrun simctl bootstatus "$sim_id" -b >/dev/null 2>&1 || true
  fi
}

build_for_testing() {
  echo "→ Building for testing…"
  if [[ "${DESTINATION_KIND}" == "device" ]]; then
    # Device builds need the app target first or the test module cannot link @testable PawMento.
    xcodebuild build -destination "$DESTINATION" "${COMMON_FLAGS[@]}"
  fi
  xcodebuild build-for-testing -destination "$DESTINATION" "${COMMON_FLAGS[@]}"
}

run_smoke() {
  prepare_destination
  local only_flags=()
  for suite in "${SMOKE_TESTS[@]}"; do
    only_flags+=(-only-testing:"$suite")
  done
  echo "→ Running smoke tests (${#SMOKE_TESTS[@]} suites)…"
  xcodebuild test-without-building -destination "$DESTINATION" "${COMMON_FLAGS[@]}" "${only_flags[@]}"
}

run_full() {
  prepare_destination
  echo "→ Running full test suite (no rebuild)…"
  xcodebuild test-without-building -destination "$DESTINATION" "${COMMON_FLAGS[@]}"
}

run_all() {
  prepare_destination
  echo "→ Building and running full test suite…"
  xcodebuild test -destination "$DESTINATION" "${COMMON_FLAGS[@]}"
}

mode="${1:-smoke}"

cd "$ROOT"
resolve_destination

case "$mode" in
  build)
    build_for_testing
    ;;
  smoke)
    run_smoke
    ;;
  full)
    run_full
    ;;
  all)
    run_all
    ;;
  *)
    echo "Unknown mode: $mode" >&2
    echo "Usage: $0 {smoke|full|build|all}" >&2
    exit 1
    ;;
esac

echo "✓ Tests passed ($mode)"
