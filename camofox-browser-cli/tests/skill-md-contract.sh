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

for needle in \
    "camofox-browser-cli" \
    "CAMOFOX_PORT" \
    "references/commands.md" \
    "references/api-reference.md" \
    "references/macros.md" \
    "references/troubleshooting.md" \
    "templates/stealth-scrape.sh" \
    "templates/multi-session.sh"
do
  if ! grep -qF "$needle" "$F"; then
    echo "FAIL: SKILL.md missing reference to '$needle'" >&2
    exit 1
  fi
done

# Check allowed-tools with fixed-string match (contains glob chars)
if ! grep -qF "allowed-tools: Bash(camofox-browser-cli:*)" "$F"; then
  echo "FAIL: SKILL.md missing 'allowed-tools: Bash(camofox-browser-cli:*)'" >&2
  exit 1
fi

for cmd in open navigate snapshot click type scroll screenshot tabs close close-all search back forward refresh health links start stop; do
  if ! grep -qE "\\bcamofox $cmd\\b|\`$cmd\\b" "$F"; then
    echo "FAIL: SKILL.md missing command '$cmd'" >&2
    exit 1
  fi
done

echo "OK: SKILL.md contract satisfied ($LINES lines)"
