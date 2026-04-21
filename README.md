# camofox-browser-skills

Two focused anti-detection browser skills for AI agents, powered by [Camoufox](https://camoufox.com/) via [jo-inc/camofox-browser](https://github.com/jo-inc/camofox-browser).

## Which skill should I install?

| Scenario | Skill |
|----------|-------|
| Local development — no server running yet | `camofox-browser-cli` (auto-installs everything) |
| Docker container, shared staging, or CI | `camofox-browser-remote` (requires `CAMOFOX_URL`) |

Both skills expose an identical command surface (`open`, `snapshot`, `click`, `type`, `screenshot`, …).

## Install

### CLI skill (local dev, auto-installs Node.js server)

Global:

    npx skills add kuo77122/camofox-browser-skills -s camofox-browser-cli -g

Project-level:

    npx skills add kuo77122/camofox-browser-skills -s camofox-browser-cli

Requires Node.js 18+. First command auto-installs `@askjo/camofox-browser` to `~/.camofox-browser/`.

### Remote skill (Docker / shared server)

Global:

    npx skills add kuo77122/camofox-browser-skills -s camofox-browser-remote -g

Project-level:

    npx skills add kuo77122/camofox-browser-skills -s camofox-browser-remote

Requires `CAMOFOX_URL` to be set before use:

    export CAMOFOX_URL=http://172.17.0.1:9377   # bridge network
    # or
    export CAMOFOX_URL=http://localhost:9377      # host network

## Quick Start

    camofox open https://example.com
    camofox snapshot
    camofox click @e1
    camofox screenshot
    camofox close

## Testing

    bash run-tests.sh

Runs all static/contract tests for both skills. Smoke tests skip if no server is reachable.

To exercise the remote skill against a running container:

    CAMOFOX_URL=http://172.17.0.1:9377 bash camofox-browser-remote/tests/smoke.sh

## License

MIT — see [LICENSE](LICENSE).
