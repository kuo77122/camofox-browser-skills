#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

F="scripts/camofox-cli.sh"
[ -x "$F" ] || { echo "FAIL: $F not executable" >&2; exit 1; }
bash -n "$F" || { echo "FAIL: $F syntax error" >&2; exit 1; }

for needle in \
    "set -euo pipefail" \
    "CAMOFOX_PORT" \
    "CAMOFOX_SESSION" \
    "ensure_server_running" \
    "strip_ref" \
    "python3 -c" \
    "/tmp/camofox-state" \
    "--port"
do
  grep -q -- "$needle" "$F" || { echo "FAIL: $F missing '$needle'" >&2; exit 1; }
done

# Every public command must be a case-branch in the script.
for cmd in start stop health open goto navigate snapshot screenshot tabs click type scroll back forward refresh search close close-all links eval help; do
  if ! grep -qE "^[[:space:]]*${cmd}\)|\\|${cmd}\)" "$F"; then
    echo "FAIL: $F missing command branch '$cmd'" >&2
    exit 1
  fi
done

# Running with no server must still print help without errors.
out=$(bash "$F" help)
echo "$out" | grep -q "USAGE" || { echo "FAIL: help didn't run cleanly" >&2; exit 1; }

echo "OK: scripts/camofox-cli.sh"
