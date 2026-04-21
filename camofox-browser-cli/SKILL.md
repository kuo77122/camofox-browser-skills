---
name: camofox-browser-cli
description: CLI-mode anti-detection browser automation using Camoufox (Firefox fork with C++ fingerprint spoofing). Auto-installs on first use — zero config needed. Use when standard browser tools get blocked by Cloudflare, Akamai, or bot detection. Triggers include "stealth browse", "anti-detection", "bypass bot", "camofox", "blocked by Cloudflare", scraping protected sites (X/Twitter, Amazon, Product Hunt), or when agent-browser/playwright fails with bot detection errors.
allowed-tools: Bash(camofox-browser-cli:*)
user_invocable: true
argument_hint: "<url or command>"
---

# Camofox Browser — CLI Mode (Auto-Install)

Stealth browser automation via Camoufox. CLI mode only — auto-installs `@askjo/camofox-browser` to `~/.camofox-browser/` on first use. Zero config needed. Requires Node.js 18+.

> **Deployment:** First use auto-installs and starts the server. To control server manually: `camofox start` / `camofox stop`.

## Quick Start

```bash
camofox open https://example.com          # Create tab + navigate
camofox snapshot                          # Get page elements with @refs
camofox click @e1                         # Click element
camofox type @e2 "hello"                  # Type text
camofox screenshot                        # Save PNG
camofox close                             # Close tab
```

## Core Workflow

1. **Navigate** — `camofox open <url>`
2. **Snapshot** — returns an accessibility tree with `@e1`, `@e2` refs (~90% smaller than raw HTML)
3. **Interact** — use refs to click, type, scroll
4. **Re-snapshot** — after any DOM change, refs are invalidated; get fresh ones
5. **Repeat** — the server stays running between commands

```bash
camofox open https://example.com/login
camofox snapshot
# @e1 [input] Email  @e2 [input] Password  @e3 [button] Sign In
camofox type @e1 "user@example.com"
camofox type @e2 "password123"
camofox click @e3
camofox snapshot                          # MUST re-snapshot after navigation
```

## Commands (at a glance)

| Category | Commands |
|---|---|
| Server | `health`, `start`, `stop` |
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
| `CAMOFOX_PORT` | `9377` | Port on `localhost` (default: 9377) |
| `CAMOFOX_SESSION` | `default` | Default session name (isolated cookies/storage) |
| `HTTPS_PROXY` | *(unset)* | Outbound proxy for the browser |

## When to Use camofox-browser-cli vs agent-browser

| Scenario | Tool |
|---|---|
| Normal websites, no bot detection | agent-browser (faster) |
| Cloudflare / Akamai protected | **camofox-browser-cli** |
| Sites that block Chromium automation | **camofox-browser-cli** |
| Need anti-fingerprinting | **camofox-browser-cli** |
| Need iOS / mobile simulation | agent-browser |
| Need video recording | agent-browser |

## Deep-Dive References

| File | Load when |
|---|---|
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
camofox close-all
camofox stop
```
