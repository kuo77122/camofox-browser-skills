#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
for f in templates/stealth-scrape.sh templates/multi-session.sh; do
    [ -x "$f" ] || { echo "FAIL: $f not executable" >&2; exit 1; }
    bash -n "$f" || { echo "FAIL: $f syntax error" >&2; exit 1; }
    grep -q "CAMOFOX=" "$f" || { echo "FAIL: $f should define CAMOFOX entrypoint" >&2; exit 1; }
done
echo "OK: templates"
