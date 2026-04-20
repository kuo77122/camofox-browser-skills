#!/usr/bin/env bash
# Unit-ish test: mode detection emits the right diagnostics.
# Does not require a live server.
set -euo pipefail
cd "$(dirname "$0")/.."
W="scripts/camofox.sh"

# Case 1: Remote mode, unreachable URL → hard error mentioning the URL + docker hint.
OUT=$(CAMOFOX_URL="http://127.0.0.1:1" bash "$W" health 2>&1 || true)
echo "$OUT" | grep -q "127.0.0.1:1"    || { echo "FAIL: remote-unreachable didn't echo base URL"; echo "$OUT"; exit 1; }
echo "$OUT" | grep -q "docker ps"      || { echo "FAIL: remote-unreachable didn't print docker hint"; echo "$OUT"; exit 1; }

# Case 2: Remote mode, start/stop must be no-ops with a note.
OUT=$(CAMOFOX_URL="http://127.0.0.1:1" bash "$W" start 2>&1 || true)
echo "$OUT" | grep -q "Remote mode"    || { echo "FAIL: remote start must note Remote mode"; echo "$OUT"; exit 1; }

OUT=$(CAMOFOX_URL="http://127.0.0.1:1" bash "$W" stop 2>&1 || true)
echo "$OUT" | grep -q "Remote mode"    || { echo "FAIL: remote stop must note Remote mode"; echo "$OUT"; exit 1; }

# Case 3: Help works in both modes without touching the network.
OUT=$(bash "$W" help)
echo "$OUT" | grep -q "USAGE"          || { echo "FAIL: CLI-mode help broken"; exit 1; }
OUT=$(CAMOFOX_URL="http://127.0.0.1:1" bash "$W" help)
echo "$OUT" | grep -q "USAGE"          || { echo "FAIL: remote-mode help broken"; exit 1; }

# Case 4: Unknown flag surfaces a usable error.
OUT=$(bash "$W" --nope 2>&1 || true)
echo "$OUT" | grep -q "Unknown flag"   || { echo "FAIL: --nope not rejected"; exit 1; }

echo "OK: mode detection behaves correctly"
