#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

check() {
  local file="$1"; shift
  for needle in "$@"; do
    if ! grep -q -- "$needle" "$file"; then
      echo "FAIL: $file missing '$needle'" >&2
      exit 1
    fi
  done
  echo "OK: $file"
}

# docker.md must cover networking, docker-compose, and the gateway address.
check references/docker.md \
  "172.17.0.1" \
  "network_mode" \
  "docker compose" \
  "CAMOFOX_URL" \
  "health"

check references/api-reference.md \
  "GET /health" \
  "POST /tabs" \
  "GET /tabs/:tabId/snapshot" \
  "POST /tabs/:tabId/click" \
  "POST /tabs/:tabId/type" \
  "POST /tabs/:tabId/scroll" \
  "POST /tabs/:tabId/navigate" \
  "GET /tabs/:tabId/screenshot" \
  "DELETE /tabs/:tabId" \
  "DELETE /sessions/:userId" \
  "GET /tabs/:tabId/links"

check references/commands.md \
  "camofox-remote open" \
  "camofox-remote navigate" \
  "camofox-remote snapshot" \
  "camofox-remote click" \
  "camofox-remote type" \
  "camofox-remote scroll" \
  "camofox-remote screenshot" \
  "camofox-remote tabs" \
  "camofox-remote close" \
  "camofox-remote close-all" \
  "camofox-remote search" \
  "camofox-remote back" \
  "camofox-remote forward" \
  "camofox-remote refresh" \
  "camofox-remote health" \
  "camofox-remote links" \
  "curl -s"

check references/macros.md \
  "@google_search" \
  "@youtube_search" \
  "@amazon_search" \
  "@reddit_search" \
  "@wikipedia_search" \
  "@twitter_search" \
  "@yelp_search" \
  "@spotify_search" \
  "@netflix_search" \
  "@linkedin_search" \
  "@instagram_search" \
  "@tiktok_search" \
  "@twitch_search"

check references/troubleshooting.md \
  "Failed to connect" \
  "docker ps" \
  "CAMOFOX_URL" \
  "Stale refs" \
  "Empty snapshot" \
  "Screenshot is 0 bytes"
