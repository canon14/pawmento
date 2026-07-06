#!/usr/bin/env bash
# PawMento test runner — tiered for speed.
#
# Usage:
#   ./Scripts/run-tests.sh smoke     # ~20s — after build, booted simulator
#   ./Scripts/run-tests.sh full      # ~3–5m — all unit tests, no rebuild
#   ./Scripts/run-tests.sh build     # compile app + tests only
#   ./Scripts/run-tests.sh all       # build + full suite (CI / pre-push)
#
# Tip: keep the simulator booted between runs:
#   xcrun simctl boot "iPhone 16 Pro"

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCHEME="PawMento"
SIMULATOR_ID="${PAWMENTO_SIMULATOR_ID:-C5B06961-D137-4318-B2A7-3164953BA621}"
DESTINATION="platform=iOS Simulator,id=${SIMULATOR_ID}"

COMMON_FLAGS=(
  -scheme "$SCHEME"
  -destination "$DESTINATION"
  -parallel-testing-enabled NO
  -quiet
)

# Fast pure-logic tests — expand when adding new focused unit suites.
SMOKE_TESTS=(
  PawMentoTests/SubscriptionEntitlementTests
  PawMentoTests/SubscriptionProductIDsTests
  PawMentoTests/AICoachClientStreamRetryTests
  PawMentoTests/LogCategoryStoredValueTests
  PawMentoTests/StorageManagerPathTests
  PawMentoTests/AuthManagerProfileTests
  PawMentoTests/InsightCalendarTests
  PawMentoTests/ReminderLogSourceKeyTests
)

boot_simulator() {
  xcrun simctl bootstatus "$SIMULATOR_ID" -b >/dev/null 2>&1 || true
}

build_for_testing() {
  echo "→ Building for testing…"
  xcodebuild build-for-testing "${COMMON_FLAGS[@]}"
}

run_smoke() {
  boot_simulator
  local only_flags=()
  for suite in "${SMOKE_TESTS[@]}"; do
    only_flags+=(-only-testing:"$suite")
  done
  echo "→ Running smoke tests (${#SMOKE_TESTS[@]} suites)…"
  xcodebuild test-without-building "${COMMON_FLAGS[@]}" "${only_flags[@]}"
}

run_full() {
  boot_simulator
  echo "→ Running full test suite (no rebuild)…"
  xcodebuild test-without-building "${COMMON_FLAGS[@]}"
}

run_all() {
  boot_simulator
  echo "→ Building and running full test suite…"
  xcodebuild test "${COMMON_FLAGS[@]}"
}

mode="${1:-smoke}"

cd "$ROOT"

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
