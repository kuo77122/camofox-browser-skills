#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

F="scripts/camofox-remote.sh"
[ -x "$F" ] || { echo "FAIL: $F not executable" >&2; exit 1; }
bash -n "$F" || { echo "FAIL: $F syntax error" >&2; exit 1; }

for needle in \
    "set -euo pipefail" \
    "CAMOFOX_URL" \
    "CAMOFOX_SESSION" \
    "ensure_server_running" \
    "strip_ref" \
    "python3 -c" \
    "/tmp/camofox-state" \
    "curl -sf"
do
  grep -q -- "$needle" "$F" || { echo "FAIL: $F missing '$needle'" >&2; exit 1; }
done

# Every public command must be a case-branch in the script.
for cmd in start stop health open goto navigate snapshot screenshot tabs click type scroll back forward refresh search close close-all links; do
  if ! grep -qE "^[[:space:]]*${cmd}\)|\\|${cmd}\)" "$F"; then
    echo "FAIL: $F missing command branch '$cmd'" >&2
    exit 1
  fi
done

# Help branch must exist.
if ! grep -qE "^[[:space:]]*--help\|-h\|help\)" "$F"; then
  echo "FAIL: $F missing help branch" >&2
  exit 1
fi

# start) branch must contain "no-op" text.
START_BODY=$(awk '/^start\)$/,/^    ;;/' "$F")
echo "$START_BODY" | grep -q "no-op" || { echo "FAIL: start) branch must mention 'no-op'" >&2; exit 1; }

# stop) branch must contain "no-op" text.
STOP_BODY=$(awk '/^stop\)$/,/^    ;;/' "$F")
echo "$STOP_BODY" | grep -q "no-op" || { echo "FAIL: stop) branch must mention 'no-op'" >&2; exit 1; }

# Help text exists.
out=$(bash "$F" help)
echo "$out" | grep -q "USAGE" || { echo "FAIL: help didn't run cleanly" >&2; exit 1; }

echo "OK: scripts/camofox-remote.sh"
