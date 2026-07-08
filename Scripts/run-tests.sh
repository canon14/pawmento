#!/usr/bin/env bash
# PawMento build verifier (unit tests removed).
#
# Usage:
#   ./Scripts/run-tests.sh smoke     # build app (default)
#   ./Scripts/run-tests.sh build     # same as smoke
#   ./Scripts/run-tests.sh full      # alias for smoke
#   ./Scripts/run-tests.sh all       # alias for smoke
#
# Destination (default: connected physical iPhone, no simulator runtime needed):
#   PAWMENTO_DEVICE_ID=<udid>   Force a specific device
#   PAWMENTO_USE_SIMULATOR=1      Use simulator instead (requires iOS Simulator runtime)
#   PAWMENTO_SIMULATOR_ID=<id>  Simulator UDID when PAWMENTO_USE_SIMULATOR=1

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
  -quiet
)

prepare_destination() {
  if [[ "${DESTINATION_KIND}" == "simulator" ]]; then
    local sim_id="${PAWMENTO_SIMULATOR_ID:-C5B06961-D137-4318-B2A7-3164953BA621}"
    xcrun simctl bootstatus "$sim_id" -b >/dev/null 2>&1 || true
  fi
}

build_app() {
  echo "→ Building app…"
  xcodebuild build -destination "$DESTINATION" "${COMMON_FLAGS[@]}"
}

mode="${1:-smoke}"

cd "$ROOT"
resolve_destination
prepare_destination
build_app

echo "✓ Build passed ($mode)"
