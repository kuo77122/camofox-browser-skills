# Command Reference

Every `camofox-remote` command, with argument signature, example, expected output, and the raw `curl` equivalent so you can script without the wrapper.

All commands run against `$CAMOFOX_URL`. `$USER_ID` = `camofox-${CAMOFOX_SESSION:-default}`. `$TAB_ID` = value stored in `/tmp/camofox-state/${CAMOFOX_SESSION:-default}.tab`.

---

## Server

### `camofox-remote health`

```bash
camofox-remote health
# → {"status":"ok"}
```

Equivalent:

```bash
curl -s "$CAMOFOX_URL/health"
```

### `camofox-remote start`

**No-op.** The server lifecycle is managed externally (Docker/systemd). Prints a message and exits 0.

```bash
camofox-remote start
# → camofox-remote: server lifecycle is managed externally (Docker/systemd). 'start' is a no-op.
```

### `camofox-remote stop`

**No-op.** The server lifecycle is managed externally (Docker/systemd). Prints a message and exits 0.

```bash
camofox-remote stop
# → camofox-remote: server lifecycle is managed externally (Docker/systemd). 'stop' is a no-op.
```

---

## Navigation

### `camofox-remote open <url>`

Create tab + navigate. Stores the new tab ID in `/tmp/camofox-state/<session>.tab`.

```bash
camofox-remote open https://example.com
# → Opened: https://example.com
#   Tab: abc123
```

Equivalent:

```bash
curl -s -X POST "$CAMOFOX_URL/tabs" \
  -H 'Content-Type: application/json' \
  -d '{"userId":"camofox-default","sessionKey":"default","url":"https://example.com"}'
```

### `camofox-remote navigate <url>`

Navigate the currently active tab (stored ID).

```bash
camofox-remote navigate https://example.com/page
```

Equivalent:

```bash
curl -s -X POST "$CAMOFOX_URL/tabs/$TAB_ID/navigate" \
  -H 'Content-Type: application/json' \
  -d '{"userId":"'$USER_ID'","url":"https://example.com/page"}'
```

### `camofox-remote back` | `forward` | `refresh`

```bash
camofox-remote back
camofox-remote forward
camofox-remote refresh
```

Equivalent (each):

```bash
curl -s -X POST "$CAMOFOX_URL/tabs/$TAB_ID/back" \
  -H 'Content-Type: application/json' \
  -d '{"userId":"'$USER_ID'"}'
```

### `camofox-remote scroll [down|up|left|right]`

Default direction: `down`.

```bash
camofox-remote scroll
camofox-remote scroll up
```

Equivalent:

```bash
curl -s -X POST "$CAMOFOX_URL/tabs/$TAB_ID/scroll" \
  -H 'Content-Type: application/json' \
  -d '{"userId":"'$USER_ID'","direction":"down"}'
```

---

## Page State

### `camofox-remote snapshot`

Text representation of the accessibility tree with `@refs`.

```bash
camofox-remote snapshot
# [button e1] Submit  [link e2] Learn more  [input e3] Email
#
# URL: https://example.com
```

Equivalent:

```bash
curl -s "$CAMOFOX_URL/tabs/$TAB_ID/snapshot?userId=$USER_ID"
```

### `camofox-remote screenshot [path]`

Default path: `/tmp/camofox-screenshots/camofox-YYYYMMDD-HHMMSS.png`.

```bash
camofox-remote screenshot
camofox-remote screenshot ./page.png
```

Equivalent:

```bash
curl -s -o ./page.png "$CAMOFOX_URL/tabs/$TAB_ID/screenshot?userId=$USER_ID"
```

### `camofox-remote tabs`

List open tabs for the current session.

```bash
camofox-remote tabs
#   abc123  https://example.com
#   def456  https://google.com
```

Equivalent:

```bash
curl -s "$CAMOFOX_URL/tabs?userId=$USER_ID"
```

### `camofox-remote links`

All anchors on the current page.

```bash
camofox-remote links
```

Equivalent:

```bash
curl -s "$CAMOFOX_URL/tabs/$TAB_ID/links?userId=$USER_ID"
```

---

## Interaction

Pass refs with the `@` prefix — the wrapper strips it before sending.

### `camofox-remote click @eN`

```bash
camofox-remote click @e1
# → Clicked: @e1
```

Equivalent:

```bash
curl -s -X POST "$CAMOFOX_URL/tabs/$TAB_ID/click" \
  -H 'Content-Type: application/json' \
  -d '{"userId":"'$USER_ID'","ref":"e1"}'
```

**Re-snapshot immediately** — the DOM may have changed.

### `camofox-remote type @eN "text"`

```bash
camofox-remote type @e3 "hello@example.com"
```

Equivalent:

```bash
curl -s -X POST "$CAMOFOX_URL/tabs/$TAB_ID/type" \
  -H 'Content-Type: application/json' \
  -d '{"userId":"'$USER_ID'","ref":"e3","text":"hello@example.com"}'
```

---

## Search Macros

### `camofox-remote search <name> "query"`

Short names auto-expand: `google` → `@google_search`.

```bash
camofox-remote search google  "best coffee beans"
camofox-remote search youtube "cooking tutorial"
```

If no active tab exists, one is created automatically.

Equivalent:

```bash
curl -s -X POST "$CAMOFOX_URL/tabs/$TAB_ID/navigate" \
  -H 'Content-Type: application/json' \
  -d '{"userId":"'$USER_ID'","macro":"@google_search","query":"best coffee beans"}'
```

Full list of macros: [macros.md](macros.md).

---

## Cleanup

### `camofox-remote close`

Closes the active tab and removes the state file.

```bash
camofox-remote close
# → Closed tab: abc123
```

Equivalent:

```bash
curl -s -X DELETE "$CAMOFOX_URL/tabs/$TAB_ID?userId=$USER_ID"
rm -f /tmp/camofox-state/${CAMOFOX_SESSION:-default}.tab
```

### `camofox-remote close-all`

Close every tab for the current user.

```bash
camofox-remote close-all
# → Closed all tabs for session: default
```

Equivalent:

```bash
curl -s -X DELETE "$CAMOFOX_URL/sessions/$USER_ID"
```

---

## Global Flags

- `--session <name>` — override `CAMOFOX_SESSION` for this call only.

```bash
camofox-remote --session work open https://mail.example.com
camofox-remote --session work snapshot
```
