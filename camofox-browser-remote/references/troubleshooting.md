# Troubleshooting

| Problem | Likely cause | Fix |
|---|---|---|
| `CAMOFOX_URL is required but not set` | `CAMOFOX_URL` env var is missing | `export CAMOFOX_URL=http://172.17.0.1:9377` (or your container's address). |
| `curl: (7) Failed to connect` | Camofox container not running, or wrong URL | Run `docker ps` on the host; start the container (`docker compose up -d camofox`). Confirm `CAMOFOX_URL` is reachable from inside the agent. |
| `cannot reach $CAMOFOX_URL` | Container stopped or networking misconfigured | Run `docker ps | grep camofox`. Check firewall rules and network bridge. |
| `{"ok":true}` never returned | Trailing slash in URL, or wrong port | `CAMOFOX_URL` must NOT have a trailing slash. Re-check value with `echo $CAMOFOX_URL`. |
| `Empty snapshot` or very short snapshot | Page still loading (SPA, JS-heavy site) | `sleep 2` (or `camofox-remote scroll down` to force hydration) then `camofox-remote snapshot` again. |
| `Stale refs` — click silently fails / "ref not found" | DOM mutated since the last snapshot | **Always re-snapshot** after `click`, `navigate`, `back`, `forward`, `refresh`, or dynamic content loads. |
| `Screenshot is 0 bytes` | Tab crashed or navigated to `about:blank` | `camofox-remote tabs` to verify the tab is still listed; if not, `camofox-remote open <url>` again. |
| `No active tab. Use 'camofox-remote open <url>' first.` | Stored tab ID was cleared by `close` or session timeout | Run `camofox-remote open <url>` to recreate. |
| Commands hang for 30+ s | Proxy misconfigured | Check `HTTPS_PROXY`; try without. Investigate container logs. |
| `docker ps` shows container but health fails | Port not exposed or wrong bridge address | Verify `docker inspect` to confirm port mapping; use correct gateway address for your networking setup. |

## Diagnostic Quick Commands

```bash
# Is CAMOFOX_URL set correctly?
echo "$CAMOFOX_URL"

# Is the base URL reachable?
curl -sv "$CAMOFOX_URL/health"

# Is the container running?
docker ps | grep camofox

# What tabs are currently open?
curl -s "$CAMOFOX_URL/tabs?userId=camofox-default"

# Where is the active tab stored?
cat /tmp/camofox-state/${CAMOFOX_SESSION:-default}.tab 2>/dev/null || echo "(none)"

# Force a clean state
camofox-remote close-all
rm -rf /tmp/camofox-state
```

## Bot-Detection Smoke Test

```bash
camofox-remote open https://bot.sannysoft.com/
camofox-remote screenshot /tmp/bot-test.png
```

Most rows should be green. If many are red, the Camofox container image may be out of date — pull a newer image and restart the container.
