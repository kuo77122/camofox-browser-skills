# Docker Setup

This skill drives a Camofox server that runs in a Docker container (or any external host). No installation happens locally — only `curl` calls to `CAMOFOX_URL`.

## Docker Compose Example

```yaml
services:
  camofox:
    image: camofox-browser:135.0.1-x86_64
    network_mode: host
    environment:
      - CAMOFOX_PORT=9377
    restart: unless-stopped
```

Start it:

```bash
docker compose up -d camofox
```

Verify it's healthy:

```bash
curl http://172.17.0.1:9377/health
# → {"ok":true,"engine":"camoufox","browserConnected":true,...}
```

## Setting CAMOFOX_URL

```bash
export CAMOFOX_URL=http://172.17.0.1:9377   # required — no default
```

`CAMOFOX_URL` must NOT have a trailing slash. Example of what NOT to do:

```bash
# WRONG — trailing slash breaks URL construction
export CAMOFOX_URL=http://172.17.0.1:9377/
```

## Networking: How to Reach the Container

The correct address depends on how both the Camofox container and the agent are networked.

| Agent networking | Camofox container | Use |
|---|---|---|
| Bridge network (default `docker run`) | `network_mode: host` | `http://172.17.0.1:9377` (Linux Docker bridge gateway) |
| `network_mode: host` (or running on host directly) | Any | `http://localhost:9377` |
| Separate named Docker network | Same named network | Service name, e.g. `http://camofox:9377` |
| macOS Docker Desktop | Any | `http://host.docker.internal:9377` |

### Bridge network (most common on Linux)

```bash
export CAMOFOX_URL=http://172.17.0.1:9377
```

`172.17.0.1` is the default Docker bridge gateway on Linux. If you changed the bridge CIDR in `/etc/docker/daemon.json`, use that gateway instead.

### Same named network (compose with multiple services)

```yaml
services:
  agent:
    networks:
      - automation
  camofox:
    image: camofox-browser:135.0.1-x86_64
    networks:
      - automation

networks:
  automation:
```

```bash
export CAMOFOX_URL=http://camofox:9377
```

### Host networking

```bash
export CAMOFOX_URL=http://localhost:9377
```

## Health Check

Always verify connectivity before running commands:

```bash
curl http://172.17.0.1:9377/health
# → {"ok":true}
```

Or via the skill:

```bash
camofox-remote health
```

## Managing the Container

```bash
# Start
docker compose up -d camofox

# Stop
docker compose stop camofox

# View logs
docker compose logs -f camofox

# Restart
docker compose restart camofox
```

The skill's `start` and `stop` commands are no-ops — use the Docker commands above to control the server lifecycle.
