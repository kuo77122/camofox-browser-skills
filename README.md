# camofox-browser-skills

Dual-mode anti-detection browser skill for AI agents, powered by [Camoufox](https://camoufox.com/) via [jo-inc/camofox-browser](https://github.com/jo-inc/camofox-browser).

Unlike upstream skill variants that assume a local CLI install, this skill works in **both** environments with the same command surface:

1. **CLI mode** — auto-installs the Node.js server on `localhost:9377`.
2. **Remote mode** — talks to an already-running server (e.g. a Docker container on `http://172.17.0.1:9377`) via `curl`, with no local dependencies beyond `bash`, `curl`, and `python3`.

## Install (Claude Code)

Global:

    npx skills add kuo77122/camofox-browser-skills -s camofox-browser -g

Project-level:

    npx skills add kuo77122/camofox-browser-skills -s camofox-browser

## Mode Selection

| Scenario | Env | Notes |
|----------|-----|-------|
| Local development | *(none)* | Auto-installs `@askjo/camofox-browser`, spawns server on `localhost:9377` |
| Custom local port | `CAMOFOX_PORT=8080` | CLI mode on a different port |
| Docker / remote | `CAMOFOX_URL=http://172.17.0.1:9377` | Skips install/start entirely |

See [camofox-browser/references/modes.md](camofox-browser/references/modes.md) for full details.

## Quick Start

    camofox open https://example.com
    camofox snapshot
    camofox click @e1
    camofox screenshot
    camofox close

## License

MIT — see [LICENSE](LICENSE).
