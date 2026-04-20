# CLI vs Remote Mode

The skill ships one wrapper (`scripts/camofox.sh`) and one command surface. The mode is decided at invocation time by environment variables — you never pass a `--mode` flag.

## Detection Order

1. **`CAMOFOX_URL` is set and non-empty** → **Remote mode**. Base URL = `$CAMOFOX_URL`. The wrapper only runs `curl`; it will not try to install or spawn anything.
2. **Otherwise** → **CLI mode**. Base URL = `http://localhost:${CAMOFOX_PORT:-9377}`. On first use, `scripts/setup.sh` installs `@askjo/camofox-browser` into `~/.camofox-browser/` and starts the server; subsequent commands reuse it.

`CAMOFOX_PORT` is ignored when `CAMOFOX_URL` is set — the URL is authoritative.

## CLI Mode

Zero configuration; useful for local dev on a laptop.

```bash
camofox open https://example.com
# First run:  [camofox] Installing @askjo/camofox-browser ...
#             [camofox] Starting server on port 9377 ...
# Subsequent: (silent; server already up)
```

**First-use contract** (binding for `scripts/camofox.sh` + `scripts/setup.sh`):

1. `scripts/camofox.sh` sees `CAMOFOX_URL` is unset → CLI mode, base URL `http://localhost:${CAMOFOX_PORT:-9377}`.
2. Health check (`curl $BASE/health`) fails.
3. If `~/.camofox-browser/start.sh` is missing, `scripts/setup.sh` runs and MUST:
   - Verify Node ≥18 (fail with an install hint otherwise)
   - `npm install @askjo/camofox-browser` into `~/.camofox-browser/`
   - Write `~/.camofox-browser/start.sh`
   - Spawn the server and wait up to 120 s for `/health`
4. The server PID MUST be written to `/tmp/camofox-state/server.pid` so `camofox stop` can terminate it.

Implementations deviating from this list must update both the script and this contract in the same commit.

**Customising the port:**

```bash
export CAMOFOX_PORT=9500
camofox open https://example.com       # → http://localhost:9500
```

**Stopping:**

```bash
camofox stop                           # kills the process in /tmp/camofox-state/server.pid
```

## Remote Mode

Used when the Camofox server is already running elsewhere — typically a Docker container alongside the agent container.

```bash
export CAMOFOX_URL=http://172.17.0.1:9377
camofox open https://example.com
```

**The wrapper will:**

- Use `$CAMOFOX_URL` verbatim as the base URL.
- Skip `setup.sh` entirely (no `npm install`, no `node` processes).
- `camofox start` / `camofox stop` become no-ops with a warning — the remote server's lifecycle is outside the skill's scope.
- Health check failures surface as `camofox: cannot reach $CAMOFOX_URL — is the container up?` with `docker ps` as a hint.

### Docker Setup (reference)

Host running a Camofox container with `docker-compose`:

```yaml
services:
  camofox:
    image: camofox-browser:135.0.1-x86_64
    network_mode: host
    environment:
      - CAMOFOX_PORT=9377
    restart: unless-stopped
```

How to reach this container from the agent depends on the agent's own networking:

- **Agent on a bridge network** (`docker run` default, most compose services): use `http://172.17.0.1:9377` — the default Docker bridge gateway on Linux. macOS Docker Desktop and Podman use different addresses (e.g. `host.docker.internal`).
- **Agent with `network_mode: host`** (or running on the host directly): use `http://localhost:9377`.
- **Agent on a separate Docker network**: use the Camofox container's service name or the host's LAN IP.

Connectivity sanity check:

```bash
curl -s "$CAMOFOX_URL/health"
# → {"status":"ok"}
```

## Environment Variable Reference

| Variable | Default | CLI mode | Remote mode |
|---|---|---|---|
| `CAMOFOX_URL` | *(unset)* | Ignored | Required; base URL |
| `CAMOFOX_PORT` | `9377` | Localhost port | Ignored |
| `CAMOFOX_SESSION` | `default` | Default session name (isolated cookies) | Same |
| `HTTPS_PROXY` | *(unset)* | Proxy for outbound browser traffic | Same |

## Precedence Examples

| Env | Resolved base URL | Mode |
|---|---|---|
| *(nothing set)* | `http://localhost:9377` | CLI |
| `CAMOFOX_PORT=8080` | `http://localhost:8080` | CLI |
| `CAMOFOX_URL=http://10.0.0.5:9377` | `http://10.0.0.5:9377` | Remote |
| `CAMOFOX_URL=http://10.0.0.5:9377` + `CAMOFOX_PORT=8080` | `http://10.0.0.5:9377` | Remote (`CAMOFOX_PORT` ignored) |

## Switching Modes Mid-Session

Safe — state is per-session (`/tmp/camofox-state/<session>.tab`) and the tab IDs are server-scoped. When you change `CAMOFOX_URL`, you're pointing at a different server, so the stored tab ID becomes meaningless. Best practice: `camofox close-all` before switching, or use a different `--session` name per server.
