#!/usr/bin/env bash
# Template: open N URLs in isolated sessions (separate cookies/storage).
#
# Usage:
#   bash multi-session.sh <url1> <url2> [url3 ...]
set -euo pipefail

CAMOFOX="${CAMOFOX:-bash $HOME/.claude/skills/camofox-browser-cli/scripts/camofox-cli.sh}"
OUT="/tmp/camofox-multi"

if [ $# -lt 2 ]; then
    echo "Usage: multi-session.sh <url1> <url2> [url3 ...]"
    echo "Each URL runs in its own session (separate cookies/storage)."
    exit 1
fi

mkdir -p "$OUT"

# Open each URL in a distinct --session.
N=0
for URL in "$@"; do
    N=$((N + 1))
    S="session-$N"
    echo "[$S] Opening: $URL"
    $CAMOFOX --session "$S" open "$URL"
done

sleep 3   # give SPA sites time to hydrate

# Capture each session's state.
N=0
for URL in "$@"; do
    N=$((N + 1))
    S="session-$N"
    echo
    echo "=== [$S] $URL ==="
    $CAMOFOX --session "$S" snapshot   > "$OUT/$S-snapshot.txt"
    $CAMOFOX --session "$S" screenshot   "$OUT/$S.png"
    echo "Saved: $OUT/$S-snapshot.txt"
    echo "Saved: $OUT/$S.png"
done

echo
ls -la "$OUT"

echo
echo "Cleaning up ..."
N=0
for _ in "$@"; do
    N=$((N + 1))
    $CAMOFOX --session "session-$N" close
done
echo "Done."
