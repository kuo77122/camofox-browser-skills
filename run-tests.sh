#!/usr/bin/env bash
# Run every static & contract test for both skills.
# Smoke tests run only when a server is reachable (exit 77 = skip).
set -euo pipefail
cd "$(dirname "$0")"

FAILED=0

run_static() {
    local skill="$1"
    echo
    echo "╔══ $skill ══╗"
    for t in "$skill"/tests/*.sh; do
        name=$(basename "$t")
        [[ "$name" == "smoke.sh" ]] && continue
        echo
        echo "── $skill/tests/$name ──"
        bash "$t" || { echo "FAIL: $name"; FAILED=$((FAILED+1)); }
    done
}

run_smoke() {
    local skill="$1"
    echo
    echo "── $skill/tests/smoke.sh (may SKIP) ──"
    set +e
    bash "$skill/tests/smoke.sh"
    rc=$?
    set -e
    case $rc in
        0)  echo "smoke ($skill): PASS" ;;
        77) echo "smoke ($skill): SKIP (no server reachable)" ;;
        *)  echo "smoke ($skill): FAIL"; FAILED=$((FAILED+1)) ;;
    esac
}

run_static camofox-browser-cli
run_static camofox-browser-remote

run_smoke camofox-browser-cli
run_smoke camofox-browser-remote

echo
if [ "$FAILED" -eq 0 ]; then
    echo "All tests green (smoke may have skipped)."
else
    echo "$FAILED test(s) FAILED."
    exit 1
fi
