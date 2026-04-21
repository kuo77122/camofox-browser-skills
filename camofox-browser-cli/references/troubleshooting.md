# Troubleshooting

| Problem | Likely cause | Fix |
|---|---|---|
| `curl: (7) Failed to connect to localhost 9377` | Server didn't start, or died | `cat /tmp/camofox-state/server.log` for the stack. Common causes: port in use, Node <18, Camoufox browser download failed. `camofox stop && camofox start`. |
| `Empty snapshot` or very short snapshot | Page still loading (SPA, JS-heavy site) | `sleep 2` (or `camofox scroll down` to force hydration) then `camofox snapshot` again. |
| `Stale refs` — click silently fails / "ref not found" | DOM mutated since the last snapshot | **Always re-snapshot** after `click`, `navigate`, `back`, `forward`, `refresh`, or dynamic content loads. |
| `Screenshot is 0 bytes` | Tab crashed or navigated to `about:blank` | `camofox tabs` to verify the tab is still listed; if not, `camofox open <url>` again. |
| `No active tab. Use 'camofox open <url>' first.` | Stored tab ID was cleared by `close` or session timeout | Run `camofox open <url>` to recreate. |
| Commands hang for 30+ s | Server is under load or proxy misconfigured | Check `HTTPS_PROXY`; try without. Kill & restart the server with `camofox stop && camofox start`. |
| `setup.sh` fails at `npm install` | Missing Node 18+ | Install Node 18+ (`brew install node`, `nvm install 18`, `apt install nodejs`). |
| `setup.sh` fails downloading Camoufox binary | Firewall / slow network | First run downloads ~300 MB. Retry; the npm package caches the binary under `~/.camofox-browser/`. |

## Diagnostic Quick Commands

```bash
# Is the server running?
curl -sv "http://localhost:${CAMOFOX_PORT:-9377}/health"

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
