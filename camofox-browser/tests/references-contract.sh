#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

check() {
  local file="$1"; shift
  for needle in "$@"; do
    if ! grep -q -- "$needle" "$file"; then
      echo "FAIL: $file missing '$needle'" >&2
      exit 1
    fi
  done
  echo "OK: $file"
}

# modes.md must cover both shapes, every env var, Docker networking, and mode-detection order.
check references/modes.md \
  "CAMOFOX_URL" \
  "CAMOFOX_PORT" \
  "CAMOFOX_SESSION" \
  "CLI mode" \
  "Remote mode" \
  "172.17.0.1" \
  "docker" \
  "health"
