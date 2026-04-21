#!/usr/bin/env bash
# Test: camofox-remote requires CAMOFOX_URL for all commands except help.
# Does not require a live server.
# Exit 0=pass, 1=fail.
set -euo pipefail
cd "$(dirname "$0")/.."

W="scripts/camofox-remote.sh"
PASS=0
FAIL=0

pass() { echo "PASS: $*"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $*" >&2; FAIL=$((FAIL + 1)); }

# ── Case 1: CAMOFOX_URL unset → exit 2 for non-help command ──
CODE=0
STDERR=$(CAMOFOX_URL="" bash "$W" health 2>&1) || CODE=$?
if [ "$CODE" -eq 2 ]; then
    pass "health with no CAMOFOX_URL exits 2"
else
    fail "health with no CAMOFOX_URL should exit 2, got $CODE"
fi

if echo "$STDERR" | grep -q "CAMOFOX_URL is required"; then
    pass "stderr contains 'CAMOFOX_URL is required'"
else
    fail "stderr missing 'CAMOFOX_URL is required' (got: $STDERR)"
fi

# Verify several other commands also exit 2 without CAMOFOX_URL
for cmd in open snapshot tabs; do
    CODE=0
    CAMOFOX_URL="" bash "$W" "$cmd" 2>/dev/null || CODE=$?
    if [ "$CODE" -eq 2 ]; then
        pass "$cmd with no CAMOFOX_URL exits 2"
    else
        fail "$cmd with no CAMOFOX_URL should exit 2, got $CODE"
    fi
done

# ── Case 2: help works without CAMOFOX_URL ──
CODE=0
OUT=$(CAMOFOX_URL="" bash "$W" help 2>&1) || CODE=$?
if [ "$CODE" -eq 0 ]; then
    pass "help exits 0 without CAMOFOX_URL"
else
    fail "help should exit 0 without CAMOFOX_URL, got $CODE"
fi

if echo "$OUT" | grep -q "USAGE"; then
    pass "help output contains 'USAGE'"
else
    fail "help output missing 'USAGE' (got: $OUT)"
fi

# Also test --help and -h variants
CODE=0
OUT=$(CAMOFOX_URL="" bash "$W" --help 2>&1) || CODE=$?
if [ "$CODE" -eq 0 ] && echo "$OUT" | grep -q "USAGE"; then
    pass "--help works without CAMOFOX_URL"
else
    fail "--help should work without CAMOFOX_URL (exit=$CODE)"
fi

# ── Case 3: CAMOFOX_URL set but unreachable → nonzero exit + "cannot reach" in stderr ──
CODE=0
STDERR=$(CAMOFOX_URL="http://127.0.0.1:1" bash "$W" health 2>&1) || CODE=$?
if [ "$CODE" -ne 0 ]; then
    pass "health with unreachable CAMOFOX_URL exits nonzero (exit=$CODE)"
else
    fail "health with unreachable CAMOFOX_URL should exit nonzero, got 0"
fi

if echo "$STDERR" | grep -q "cannot reach"; then
    pass "stderr contains 'cannot reach' for unreachable server"
else
    fail "stderr missing 'cannot reach' for unreachable server (got: $STDERR)"
fi

# ── Summary ──
echo ""
echo "Results: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
exit 0
