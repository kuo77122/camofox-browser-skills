#!/usr/bin/env bash
# End-to-end smoke test — mode-agnostic.
# Exit 0=pass, 77=skip (no server), other=fail.
set -euo pipefail
cd "$(dirname "$0")/.."

W="./scripts/camofox.sh"
SESSION="smoke-$$"

BASE="${CAMOFOX_URL:-http://localhost:${CAMOFOX_PORT:-9377}}"
echo "Smoke test against: $BASE"

if ! curl -sf "$BASE/health" >/dev/null 2>&1; then
    if [ -n "${CAMOFOX_URL:-}" ]; then
        echo "SKIP: remote server at $CAMOFOX_URL is not reachable"
        exit 77
    fi
    echo "SKIP: no local server and auto-install is out-of-scope for CI smoke"
    exit 77
fi

step() { echo; echo "── $* ──"; }

cleanup() { bash "$W" --session "$SESSION" close-all >/dev/null 2>&1 || true; }
trap cleanup EXIT

step "health"
bash "$W" health | grep -q '"status":"ok"'

step "open"
bash "$W" --session "$SESSION" open "https://example.com" | grep -q "^Tab: "

step "snapshot"
SNAP=$(bash "$W" --session "$SESSION" snapshot)
echo "$SNAP" | head -n 3
echo "$SNAP" | grep -q "URL: https://example.com"

step "screenshot"
PNG="/tmp/camofox-smoke-$$.png"
bash "$W" --session "$SESSION" screenshot "$PNG"
[ -s "$PNG" ] || { echo "FAIL: screenshot is empty"; exit 1; }
file "$PNG" | grep -qi "PNG image"
rm -f "$PNG"

step "tabs"
bash "$W" --session "$SESSION" tabs | grep -q "https://example.com"

step "close"
bash "$W" --session "$SESSION" close | grep -q "^Closed tab:"

echo
echo "OK: smoke test passed"
