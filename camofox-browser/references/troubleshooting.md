# Troubleshooting

| Problem | Likely cause | Fix |
|---|---|---|
| `curl: (7) Failed to connect to ... 9377` (Remote mode) | Camofox container not running | Run `docker ps` on the host; start the container (`docker compose up -d camofox`). Confirm `CAMOFOX_URL` is reachable from inside the agent container. |
| `curl: (7) Failed to connect to localhost 9377` (CLI mode) | Server didn't start, or died | `cat /tmp/camofox-state/server.log` for the stack. Common causes: port in use, Node <18, Camoufox browser download failed. `camofox stop && camofox start`. |
| `{"ok":true}` never returned | Wrong port / URL | Remote: re-check `CAMOFOX_URL` (no trailing slash). CLI: `echo $CAMOFOX_PORT`; it must match the server's `PORT` env. |
| `Empty snapshot` or very short snapshot | Page still loading (SPA, JS-heavy site) | `sleep 2` (or `camofox scroll down` to force hydration) then `camofox snapshot` again. |
| `Stale refs` — click silently fails / "ref not found" | DOM mutated since the last snapshot | **Always re-snapshot** after `click`, `navigate`, `back`, `forward`, `refresh`, or dynamic content loads. |
| `Screenshot is 0 bytes` | Tab crashed or navigated to `about:blank` | `camofox tabs` to verify the tab is still listed; if not, `camofox open <url>` again. |
| `No active tab. Use 'camofox open <url>' first.` | Stored tab ID was cleared by `close` or session timeout | Run `camofox open <url>` to recreate. |
| Commands hang for 30+ s | Server is under load or proxy misconfigured | Check `HTTPS_PROXY`; try without. Kill & restart the server (CLI mode). |
| `setup.sh` fails at `npm install` (CLI mode) | Missing Node 18+ | Install Node 18+ (`brew install node`, `nvm install 18`, `apt install nodejs`). |
| `setup.sh` fails downloading Camoufox binary | Firewall / slow network | First run downloads ~300 MB. Retry; the npm package caches the binary under `~/.camofox-browser/`. |
| Remote mode: `camofox start` / `stop` printed a warning | Expected | Lifecycle of the remote server is outside the skill's scope — manage it with `docker` / `systemctl`. |

## Diagnostic Quick Commands

```bash
# Is the base URL resolvable?
curl -sv "$BASE/health"

# What mode am I in?
[ -n "${CAMOFOX_URL:-}" ] && echo "Remote: $CAMOFOX_URL" || echo "CLI: http://localhost:${CAMOFOX_PORT:-9377}"

# CLI mode: show server log
tail -n 50 /tmp/camofox-state/server.log

# Where is the active tab stored?
cat /tmp/camofox-state/${CAMOFOX_SESSION:-default}.tab 2>/dev/null || echo "(none)"

# Force a clean state
camofox close-all
rm -rf /tmp/camofox-state
```

## Bot-Detection Smoke Test

```bash
camofox open https://bot.sannysoft.com/
camofox screenshot /tmp/bot-test.png
```

Most rows should be green. If many are red, your Camofox version is out of date (CLI mode: `rm -rf ~/.camofox-browser && camofox start` to reinstall).
