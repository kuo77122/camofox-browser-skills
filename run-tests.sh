#!/usr/bin/env bash
# Run every static & contract test in the skill.
# Smoke test runs only when a server is reachable (exit 77 = skip).
set -euo pipefail
cd "$(dirname "$0")"

ROOT="camofox-browser/tests"

for t in \
    "$ROOT/skill-md-contract.sh" \
    "$ROOT/references-contract.sh" \
    "$ROOT/setup-sh.sh" \
    "$ROOT/camofox-sh-static.sh" \
    "$ROOT/mode-detection.sh" \
    "$ROOT/templates-syntax.sh"
do
    echo
    echo "── $t ──"
    bash "$t"
done

echo
echo "── $ROOT/smoke.sh (may SKIP) ──"
set +e
bash "$ROOT/smoke.sh"
rc=$?
set -e
case $rc in
    0)  echo "smoke: PASS" ;;
    77) echo "smoke: SKIP (no server reachable)" ;;
    *)  echo "smoke: FAIL"; exit $rc ;;
esac

echo
echo "All tests green (smoke may have skipped)."
