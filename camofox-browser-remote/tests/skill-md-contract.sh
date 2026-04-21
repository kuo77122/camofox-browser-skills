#!/usr/bin/env bash
# Contract: SKILL.md is short, self-describing, and links to every reference.
set -euo pipefail
cd "$(dirname "$0")/.."

F="SKILL.md"
LINES=$(wc -l < "$F")
if [ "$LINES" -gt 180 ]; then
  echo "FAIL: SKILL.md is $LINES lines (budget: 180)" >&2
  exit 1
fi

# Check header frontmatter
grep -q "name: camofox-browser-remote" "$F" || { echo "FAIL: SKILL.md missing 'name: camofox-browser-remote'" >&2; exit 1; }
grep -q "allowed-tools: Bash(camofox-browser-remote:\*)" "$F" || { echo "FAIL: SKILL.md missing correct allowed-tools" >&2; exit 1; }

for needle in \
    "CAMOFOX_URL" \
    "references/docker.md" \
    "references/commands.md" \
    "references/api-reference.md" \
    "references/macros.md" \
    "references/troubleshooting.md" \
    "templates/stealth-scrape.sh" \
    "templates/multi-session.sh"
do
  if ! grep -q "$needle" "$F"; then
    echo "FAIL: SKILL.md missing reference to '$needle'" >&2
    exit 1
  fi
done

# Core commands must appear (start/stop are noted as no-ops but must still appear)
for cmd in open navigate snapshot click type scroll screenshot tabs close close-all search back forward refresh health links start stop; do
  if ! grep -qE "\\bcamofox(-remote)? $cmd\\b|\`$cmd\\b" "$F"; then
    echo "FAIL: SKILL.md missing command '$cmd'" >&2
    exit 1
  fi
done

echo "OK: SKILL.md contract satisfied ($LINES lines)"
