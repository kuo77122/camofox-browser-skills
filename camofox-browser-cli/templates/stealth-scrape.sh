#!/usr/bin/env bash
# Template: anti-detection scrape using camofox-browser-cli (CLI mode only).
#
# Usage:
#   bash stealth-scrape.sh <url> [output-dir]
set -euo pipefail

CAMOFOX="${CAMOFOX:-bash $HOME/.claude/skills/camofox-browser-cli/scripts/camofox-cli.sh}"
URL="${1:?Usage: stealth-scrape.sh <url> [output-dir]}"
OUT="${2:-/tmp/camofox-scrape}"

mkdir -p "$OUT"
echo "Stealth scraping: $URL"
echo "Output:           $OUT"
echo "Base URL:         http://localhost:${CAMOFOX_PORT:-9377}"

$CAMOFOX open "$URL"
sleep 3                                    # allow SPA hydration

$CAMOFOX screenshot "$OUT/page.png"
$CAMOFOX snapshot > "$OUT/snapshot.txt"
$CAMOFOX links > "$OUT/links.json" 2>/dev/null || true

for i in 1 2 3; do
    echo "Scrolling ($i/3) ..."
    $CAMOFOX scroll down
    sleep 1
done

$CAMOFOX snapshot > "$OUT/snapshot-scrolled.txt"
$CAMOFOX screenshot "$OUT/page-scrolled.png"

echo
echo "Done. Artifacts:"
ls -la "$OUT"

$CAMOFOX close
