---
name: camofox-browser-remote
description: Remote-mode anti-detection browser automation using Camoufox (Firefox fork with C++ fingerprint spoofing). Requires CAMOFOX_URL pointing to an externally-managed server (Docker container, shared staging, CI). Use when standard browser tools get blocked by Cloudflare, Akamai, or bot detection and a Camofox server is already running. Triggers include "stealth browse", "anti-detection", "bypass bot", "camofox", "blocked by Cloudflare", scraping protected sites (X/Twitter, Amazon, Product Hunt), or when agent-browser/playwright fails with bot detection errors.
allowed-tools: Bash(camofox-browser-remote:*)
user_invocable: true
argument_hint: "<url or command>"
---

# Camofox Browser — Remote Mode (Docker / Shared Server)

Stealth browser automation via Camoufox. Drives an externally-managed server over HTTP — no install, no local Node process.

## Setup (required)

```bash
export CAMOFOX_URL=http://172.17.0.1:9377   # required — no default
```

The server runs externally (Docker container, shared staging, CI). This skill only drives it.
See [references/docker.md](references/docker.md) for Docker networking details.

> **If `camofox-remote` is not found on PATH:** set an alias using the script that ships with this skill. Replace `<SKILL_DIR>` with the directory containing this SKILL.md file:
> ```bash
> alias camofox-remote="bash <SKILL_DIR>/scripts/camofox-remote.sh"
> ```
> Example: if this SKILL.md is at `~/my-skills/camofox-browser-remote/SKILL.md`, use `~/my-skills/camofox-browser-remote`.

> **Trust requirement:** Every command — page snapshots, screenshots, typed text, navigation history — is sent over HTTP to `CAMOFOX_URL`. Only point this at a server you own and control. Do not use a shared or third-party endpoint if you will visit sites with credentials or sensitive data.

## Quick Start

```bash
camofox-remote open https://example.com      # Create tab + navigate
camofox-remote snapshot                      # Get page elements with @refs
camofox-remote click @e1                     # Click element
camofox-remote type @e2 "hello"              # Type text
camofox-remote screenshot                    # Save PNG
camofox-remote close                         # Close tab
```

## Core Workflow

1. **Navigate** — `camofox-remote open <url>`
2. **Snapshot** — returns an accessibility tree with `@e1`, `@e2` refs (~90% smaller than raw HTML)
3. **Interact** — use refs to click, type, scroll
4. **Re-snapshot** — after any DOM change, refs are invalidated; get fresh ones
5. **Repeat** — the server stays running between commands

```bash
camofox-remote open https://example.com/search
camofox-remote snapshot
# @e1 [input] Search box  @e2 [button] Submit
camofox-remote type @e1 "camoufox anti-detection"
camofox-remote click @e2
camofox-remote snapshot                      # MUST re-snapshot after navigation
```

## Commands (at a glance)

| Category | Commands |
|---|---|
| Server | `health`, `start` (no-op — manage container externally), `stop` (no-op — manage container externally) |
| Navigation | `open <url>`, `navigate <url>`, `back`, `forward`, `refresh`, `scroll [down\|up\|left\|right]` |
| Page state | `snapshot`, `screenshot [path]`, `tabs`, `links` |
| Interaction | `click @eN`, `type @eN "text"` |
| Search | `search google "query"` (13 macros — see [references/macros.md](references/macros.md)) |
| Session | `--session <name> <cmd>`, `close`, `close-all` |

Full reference with `curl` equivalents: [references/commands.md](references/commands.md).

## Ref Lifecycle (critical)

Refs (`@e1`, `@e2`) are invalidated whenever the DOM changes. Always re-snapshot after:

- Clicking links/buttons that navigate
- Form submissions
- Dynamic content loads (infinite scroll, SPA route change)

## Environment Variables

| Variable | Default | Meaning |
|---|---|---|
| `CAMOFOX_URL` | **REQUIRED** | Remote base URL — e.g. `http://172.17.0.1:9377`. No default. |
| `CAMOFOX_SESSION` | `default` | Default session name (isolated cookies/storage) |
| `HTTPS_PROXY` | *(unset)* | Outbound proxy for the browser |

## When to Use camofox-browser-remote vs agent-browser

| Scenario | Tool |
|---|---|
| Normal websites, no bot detection | agent-browser (faster) |
| Cloudflare / Akamai protected | **camofox-browser-remote** |
| Sites that block Chromium automation | **camofox-browser-remote** |
| Need anti-fingerprinting | **camofox-browser-remote** |
| Need iOS / mobile simulation | agent-browser |
| Need video recording | agent-browser |

## Deep-Dive References

| File | Load when |
|---|---|
| [references/docker.md](references/docker.md) | Docker setup, networking, compose example, `CAMOFOX_URL` configuration |
| [references/commands.md](references/commands.md) | Need exact args, output format, or `curl` equivalent of any command |
| [references/api-reference.md](references/api-reference.md) | Calling an endpoint the wrapper doesn't expose |
| [references/macros.md](references/macros.md) | Using search macros (`@google_search`, etc.) |
| [references/troubleshooting.md](references/troubleshooting.md) | Debugging failures (connect refused, stale refs, empty snapshots) |

## Ready-to-Use Templates

| File | Description |
|---|---|
| [templates/stealth-scrape.sh](templates/stealth-scrape.sh) | Full anti-detection scrape (screenshot + snapshot + links) |
| [templates/multi-session.sh](templates/multi-session.sh) | Parallel URLs in isolated sessions |

## Cleanup

Always close when done:

```bash
camofox-remote close-all
camofox-remote stop    # no-op in remote mode; manage the container externally
```
