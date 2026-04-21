#!/usr/bin/env bash
# camofox-remote — Remote-mode wrapper for camofox-browser-remote skill
#
# Requires CAMOFOX_URL to be set (e.g. http://172.17.0.1:9377).
# The server runs externally (Docker container, shared staging, CI).
# This script only drives it via curl — no install, no spawn.
set -euo pipefail

# ── Configuration ──
CAMOFOX_SESSION="${CAMOFOX_SESSION:-default}"
STATE_DIR="/tmp/camofox-state"
SCREENSHOT_DIR="/tmp/camofox-screenshots"

# ── Parse global flags ──
COMMAND=""
while [[ "${1:-}" == --* ]]; do
    case "$1" in
        --session) CAMOFOX_SESSION="$2"; shift 2 ;;
        --help|-h) COMMAND="help"; shift; break ;;
        --port)
            echo "camofox-remote: --port is not supported in remote mode" >&2
            exit 1
            ;;
        *) echo "Unknown flag: $1" >&2; exit 1 ;;
    esac
done

if [ -z "$COMMAND" ]; then
    COMMAND="${1:-help}"
    shift || true
fi

# ── Remote mode: CAMOFOX_URL is required (except for help) ──
case "${COMMAND}" in
    help|--help|-h) : ;;
    *)
        if [ -z "${CAMOFOX_URL:-}" ]; then
            echo "camofox-remote: CAMOFOX_URL is required but not set." >&2
            echo "  Example: export CAMOFOX_URL=http://172.17.0.1:9377" >&2
            echo "  For local auto-install, use the camofox-browser-cli skill instead." >&2
            exit 2
        fi
        ;;
esac
CAMOFOX_BASE="${CAMOFOX_URL:-}"
CAMOFOX_BASE="${CAMOFOX_BASE%/}"

TAB_FILE="$STATE_DIR/${CAMOFOX_SESSION}.tab"
USER_ID="camofox-${CAMOFOX_SESSION}"

# ── HTTP helpers ──
api() {
    local method="$1" path="$2"; shift 2
    curl -sf -X "$method" -H 'Content-Type: application/json' \
         "$CAMOFOX_BASE$path" "$@"
}
api_json() {
    local method="$1" path="$2" body="$3"
    curl -sf -X "$method" -H 'Content-Type: application/json' \
         -d "$body" "$CAMOFOX_BASE$path"
}
json_field() {
    # Usage: json_field FIELD  (reads stdin)
    python3 -c "import sys,json; print(json.load(sys.stdin).get('$1',''))" 2>/dev/null || echo ""
}

get_active_tab() { [ -f "$TAB_FILE" ] && cat "$TAB_FILE" || true; }
set_active_tab() { mkdir -p "$STATE_DIR"; echo "$1" > "$TAB_FILE"; }

require_active_tab() {
    local t; t=$(get_active_tab)
    if [ -z "$t" ]; then
        echo "No active tab. Use 'camofox-remote open <url>' first." >&2
        exit 1
    fi
    echo "$t"
}

strip_ref() { echo "${1#@}"; }   # @e1 → e1

# ── Connectivity check (remote only) ──
ensure_server_running() {
    if ! curl -sf "$CAMOFOX_BASE/health" >/dev/null 2>&1; then
        echo "camofox-remote: cannot reach $CAMOFOX_BASE — is the container running?" >&2
        echo "  Hint: docker ps | grep camofox" >&2
        exit 1
    fi
}

# ── Commands ──
case "$COMMAND" in

# Server control (no-ops in remote mode)
start)
    echo "camofox-remote: server lifecycle is managed externally (Docker/systemd). 'start' is a no-op."
    exit 0
    ;;
stop)
    echo "camofox-remote: server lifecycle is managed externally (Docker/systemd). 'stop' is a no-op."
    exit 0
    ;;
health)
    ensure_server_running
    api GET /health
    echo ""
    ;;

# Tab creation / navigation
open)
    URL="${1:?Usage: camofox-remote open <url>}"
    ensure_server_running
    RESP=$(api_json POST /tabs \
        "{\"userId\":\"$USER_ID\",\"sessionKey\":\"$CAMOFOX_SESSION\",\"url\":\"$URL\"}")
    TAB_ID=$(echo "$RESP" | json_field tabId)
    [ -n "$TAB_ID" ] || { echo "Failed to create tab. Response: $RESP" >&2; exit 1; }
    set_active_tab "$TAB_ID"
    echo "Opened: $URL"
    echo "Tab: $TAB_ID"
    ;;
goto)
    URL="${1:?Usage: camofox-remote goto <url>}"
    ensure_server_running
    RESP=$(api_json POST /tabs \
        "{\"userId\":\"$USER_ID\",\"sessionKey\":\"$CAMOFOX_SESSION\",\"url\":\"$URL\"}")
    TAB_ID=$(echo "$RESP" | json_field tabId)
    [ -n "$TAB_ID" ] || { echo "Failed to create tab. Response: $RESP" >&2; exit 1; }
    set_active_tab "$TAB_ID"
    echo "Opened: $URL"
    echo "Tab: $TAB_ID"
    ;;
navigate)
    URL="${1:?Usage: camofox-remote navigate <url>}"
    TAB_ID=$(require_active_tab)
    ensure_server_running
    api_json POST "/tabs/$TAB_ID/navigate" "{\"userId\":\"$USER_ID\",\"url\":\"$URL\"}"
    echo ""
    ;;

# Page state
snapshot)
    TAB_ID=$(require_active_tab)
    ensure_server_running
    RESP=$(api GET "/tabs/$TAB_ID/snapshot?userId=$USER_ID")
    echo "$RESP" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(d.get('snapshot', ''))
print()
print('URL:', d.get('url',''))
" 2>/dev/null || echo "$RESP"
    ;;
screenshot)
    TAB_ID=$(require_active_tab)
    ensure_server_running
    mkdir -p "$SCREENSHOT_DIR"
    OUT="${1:-$SCREENSHOT_DIR/camofox-$(date +%Y%m%d-%H%M%S).png}"
    curl -sf -o "$OUT" "$CAMOFOX_BASE/tabs/$TAB_ID/screenshot?userId=$USER_ID"
    [ -s "$OUT" ] || { echo "Failed to capture screenshot" >&2; exit 1; }
    echo "Screenshot saved: $OUT"
    ;;
tabs)
    ensure_server_running
    RESP=$(api GET "/tabs?userId=$USER_ID")
    echo "$RESP" | python3 -c "
import sys, json
d = json.load(sys.stdin)
tabs = d if isinstance(d, list) else d.get('tabs', [])
if not tabs:
    print('No open tabs')
else:
    for t in tabs:
        print(f\"  {t.get('tabId', t.get('id','?'))}  {t.get('url','?')}\")
" 2>/dev/null || echo "$RESP"
    ;;
links)
    TAB_ID=$(require_active_tab)
    ensure_server_running
    api GET "/tabs/$TAB_ID/links?userId=$USER_ID"
    echo ""
    ;;

# Interaction
click)
    REF="${1:?Usage: camofox-remote click @e1}"
    TAB_ID=$(require_active_tab)
    ensure_server_running
    R=$(strip_ref "$REF")
    api_json POST "/tabs/$TAB_ID/click" "{\"userId\":\"$USER_ID\",\"ref\":\"$R\"}"
    echo "Clicked: $REF"
    ;;
type)
    REF="${1:?Usage: camofox-remote type @e1 \"text\"}"
    TEXT="${2:?Usage: camofox-remote type @e1 \"text\"}"
    TAB_ID=$(require_active_tab)
    ensure_server_running
    R=$(strip_ref "$REF")
    BODY=$(python3 -c "
import json, sys
print(json.dumps({'userId': sys.argv[1], 'ref': sys.argv[2], 'text': sys.argv[3]}))
" "$USER_ID" "$R" "$TEXT")
    api_json POST "/tabs/$TAB_ID/type" "$BODY"
    echo "Typed into $REF: $TEXT"
    ;;
scroll)
    DIR="${1:-down}"
    TAB_ID=$(require_active_tab)
    ensure_server_running
    api_json POST "/tabs/$TAB_ID/scroll" "{\"userId\":\"$USER_ID\",\"direction\":\"$DIR\"}"
    echo "Scrolled $DIR"
    ;;

# History
back)
    TAB_ID=$(require_active_tab); ensure_server_running
    api_json POST "/tabs/$TAB_ID/back" "{\"userId\":\"$USER_ID\"}"
    echo "Navigated back"
    ;;
forward)
    TAB_ID=$(require_active_tab); ensure_server_running
    api_json POST "/tabs/$TAB_ID/forward" "{\"userId\":\"$USER_ID\"}"
    echo "Navigated forward"
    ;;
refresh)
    TAB_ID=$(require_active_tab); ensure_server_running
    api_json POST "/tabs/$TAB_ID/refresh" "{\"userId\":\"$USER_ID\"}"
    echo "Page refreshed"
    ;;

# Search macros
search)
    MACRO="${1:?Usage: camofox-remote search google \"query\"}"
    QUERY="${2:?Usage: camofox-remote search google \"query\"}"
    TAB_ID=$(get_active_tab)
    ensure_server_running
    if [ -z "$TAB_ID" ]; then
        RESP=$(api_json POST /tabs "{\"userId\":\"$USER_ID\",\"sessionKey\":\"$CAMOFOX_SESSION\"}")
        TAB_ID=$(echo "$RESP" | json_field tabId)
        [ -n "$TAB_ID" ] || { echo "Failed to create tab" >&2; exit 1; }
        set_active_tab "$TAB_ID"
    fi
    case "$MACRO" in
        @*) MF="$MACRO" ;;
        *)  MF="@${MACRO}_search" ;;
    esac
    BODY=$(python3 -c "
import json, sys
print(json.dumps({'userId': sys.argv[1], 'macro': sys.argv[2], 'query': sys.argv[3]}))
" "$USER_ID" "$MF" "$QUERY")
    api_json POST "/tabs/$TAB_ID/navigate" "$BODY"
    echo "Searched $MF: $QUERY"
    ;;

# Cleanup
close)
    TAB_ID=$(get_active_tab)
    if [ -n "$TAB_ID" ]; then
        ensure_server_running
        api DELETE "/tabs/$TAB_ID?userId=$USER_ID" || true
        rm -f "$TAB_FILE"
        echo "Closed tab: $TAB_ID"
    else
        echo "No active tab to close"
    fi
    ;;
close-all)
    ensure_server_running
    api DELETE "/sessions/$USER_ID" || true
    rm -f "$STATE_DIR/${CAMOFOX_SESSION}.tab"
    echo "Closed all tabs for session: $CAMOFOX_SESSION"
    ;;

--help|-h|help)
    cat <<HELP
camofox-remote — Remote-mode anti-detection browser (Docker/shared)

USAGE:
  camofox-remote [--session NAME] <command> [args]

The server runs externally (Docker container, shared staging, CI).
Set CAMOFOX_URL before calling any command (except help).

SERVER (managed externally):
  start                       No-op — manage the container externally
  stop                        No-op — manage the container externally
  health                      Health check against \$CAMOFOX_URL

NAVIGATION:
  open <url>                  Open URL in new tab
  navigate <url>              Navigate current tab
  back / forward / refresh    History navigation
  scroll [down|up|left|right] Scroll page

PAGE STATE:
  snapshot                    Accessibility snapshot with @refs
  screenshot [path]           Save screenshot
  tabs                        List open tabs
  links                       All anchors on current page

INTERACTION:
  click @e1                   Click element by ref
  type @e1 "text"             Type into element

SEARCH (13 macros):
  search google "query"       google, youtube, amazon, reddit, wikipedia,
                              twitter, yelp, spotify, netflix, linkedin,
                              instagram, tiktok, twitch

CLEANUP:
  close                       Close current tab
  close-all                   Close all tabs in session

OPTIONS:
  --session NAME              Named session (default: "default")

ENVIRONMENT:
  CAMOFOX_URL   (REQUIRED)    Remote base URL — e.g. http://172.17.0.1:9377
  CAMOFOX_SESSION             Default session name
  HTTPS_PROXY                 Outbound proxy for browser traffic
HELP
    ;;

*)
    echo "Unknown command: $COMMAND" >&2
    echo "Run 'camofox-remote help' for usage." >&2
    exit 1
    ;;
esac
