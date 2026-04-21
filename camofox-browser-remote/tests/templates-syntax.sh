#!/usr/bin/env bash
# Test: template files have valid bash syntax, are executable, and reference CAMOFOX_URL.
set -euo pipefail
cd "$(dirname "$0")/.."

PASS=0
FAIL=0

pass() { echo "PASS: $*"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $*" >&2; FAIL=$((FAIL + 1)); }

check_template() {
    local f="$1"

    # Valid bash syntax
    if bash -n "$f" 2>/dev/null; then
        pass "$f: valid bash syntax"
    else
        fail "$f: syntax error"
    fi

    # Executable
    if [ -x "$f" ]; then
        pass "$f: is executable"
    else
        fail "$f: not executable"
    fi

    # References CAMOFOX_URL
    if grep -q "CAMOFOX_URL" "$f"; then
        pass "$f: contains CAMOFOX_URL reference"
    else
        fail "$f: missing CAMOFOX_URL reference"
    fi
}

check_template "templates/stealth-scrape.sh"
check_template "templates/multi-session.sh"

echo ""
echo "Results: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
exit 0
