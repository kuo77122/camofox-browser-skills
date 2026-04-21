#!/usr/bin/env bash
# End-to-end smoke test — remote mode only.
# Exit 0=pass, 77=skip (CAMOFOX_URL not set or server unreachable), other=fail.
set -euo pipefail
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$SKILL_DIR"

W="$SKILL_DIR/scripts/camofox-remote.sh"
SESSION="smoke-$$"

# Skip if CAMOFOX_URL is not set
if [ -z "${CAMOFOX_URL:-}" ]; then
    echo "SKIP: CAMOFOX_URL not set"
    exit 77
fi

echo "Smoke test against: $CAMOFOX_URL"

# Skip if server not reachable
if ! curl -sf "$CAMOFOX_URL/health" >/dev/null 2>&1; then
    echo "SKIP: remote server at $CAMOFOX_URL is not reachable"
    exit 77
fi

step() { echo; echo "── $* ──"; }

cleanup() { bash "$W" --session "$SESSION" close-all >/dev/null 2>&1 || true; }
trap cleanup EXIT

step "health"
bash "$W" health | grep -qE '"ok":true|"status":"ok"'

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
bash "$W" --session "$SESSION" close | grep -q "Closed tab:"

echo
echo "OK: smoke test passed"
