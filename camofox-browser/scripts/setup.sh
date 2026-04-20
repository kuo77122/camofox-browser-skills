#!/usr/bin/env bash
# camofox-browser setup — CLI-mode only, one-time installation.
# Called on-demand by camofox.sh when CAMOFOX_URL is unset and
# the server is not yet installed locally.
set -euo pipefail

INSTALL_DIR="$HOME/.camofox-browser"
CAMOFOX_PORT="${CAMOFOX_PORT:-9377}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

info() { echo "  [camofox] $*"; }
ok()   { echo "  [camofox] ✓ $*"; }
fail() { echo "  [camofox] ✗ $*" >&2; exit 1; }

# ── Step 1: Node.js >= 18 ──
command -v node >/dev/null 2>&1 || fail "Node.js not found. Install Node 18+ (e.g. brew install node)"
NODE_MAJOR=$(node -v | sed 's/v//' | cut -d. -f1)
[ "$NODE_MAJOR" -ge 18 ] || fail "Node.js >= 18 required (found $(node -v))"
ok "Node.js $(node -v)"

# ── Step 2: Install or update @askjo/camofox-browser ──
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"
if [ -d "node_modules/@askjo/camofox-browser" ]; then
    info "Updating @askjo/camofox-browser in $INSTALL_DIR ..."
    npm update @askjo/camofox-browser --silent
else
    info "Installing @askjo/camofox-browser into $INSTALL_DIR ..."
    [ -f package.json ] || npm init -y --silent >/dev/null
    npm install @askjo/camofox-browser --silent
fi
ok "Package installed"

# ── Step 3: Launch script ──
cat > "$INSTALL_DIR/start.sh" <<'LAUNCH'
#!/usr/bin/env bash
set -euo pipefail
INSTALL_DIR="$HOME/.camofox-browser"
export PORT="${CAMOFOX_PORT:-9377}"
cd "$INSTALL_DIR/node_modules/@askjo/camofox-browser"
exec node server.js
LAUNCH
chmod +x "$INSTALL_DIR/start.sh"
ok "Launch script created"

# ── Step 4: State directories ──
mkdir -p /tmp/camofox-state /tmp/camofox-screenshots
ok "State directories ready"

# ── Step 5: First boot (downloads Camoufox, ~300 MB on first run) ──
info "Starting server on port $CAMOFOX_PORT (first run downloads Camoufox, ~300 MB) ..."
export PORT="$CAMOFOX_PORT"
cd "$INSTALL_DIR/node_modules/@askjo/camofox-browser"
nohup node server.js > /tmp/camofox-state/server.log 2>&1 &
PID=$!
echo "$PID" > /tmp/camofox-state/server.pid

for _ in $(seq 1 120); do
    if curl -sf "http://localhost:$CAMOFOX_PORT/health" >/dev/null 2>&1; then
        ok "Server running (PID $PID, port $CAMOFOX_PORT)"
        exit 0
    fi
    kill -0 "$PID" 2>/dev/null || {
        echo "" >&2
        echo "Server died. Last 20 lines of log:" >&2
        tail -n 20 /tmp/camofox-state/server.log >&2 || true
        fail "Server failed to start"
    }
    sleep 2
done

fail "Server did not become healthy within 240 s (check /tmp/camofox-state/server.log)"
