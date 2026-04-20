#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

F="scripts/setup.sh"

[ -x "$F" ] || { echo "FAIL: $F not executable" >&2; exit 1; }
bash -n "$F" || { echo "FAIL: $F syntax error" >&2; exit 1; }

for needle in \
    "set -euo pipefail" \
    "INSTALL_DIR=\"\$HOME/.camofox-browser\"" \
    "CAMOFOX_PORT=\"\${CAMOFOX_PORT:-9377}\"" \
    "npm install @askjo/camofox-browser" \
    "node -v" \
    "/tmp/camofox-state" \
    "start.sh"
do
  if ! grep -q -- "$needle" "$F"; then
    echo "FAIL: $F missing '$needle'" >&2
    exit 1
  fi
done

echo "OK: scripts/setup.sh"
