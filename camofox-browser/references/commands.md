# Command Reference

Every `camofox` command, with argument signature, example, expected output, and the raw `curl` equivalent so you can script without the wrapper.

`$BASE` = resolved base URL (see [modes.md](modes.md)). `$USER_ID` = `camofox-${CAMOFOX_SESSION:-default}`. `$TAB_ID` = value stored in `/tmp/camofox-state/${CAMOFOX_SESSION:-default}.tab`.

---

## Server

### `camofox health`

```bash
camofox health
# → {"status":"ok"}
```

Equivalent:

```bash
curl -s "$BASE/health"
```

### `camofox start` / `camofox stop`

CLI mode: spawns / kills `node server.js`. Remote mode: no-op with warning (the server's lifecycle is out of scope).

---

## Navigation

### `camofox open <url>`

Create tab + navigate. Stores the new tab ID in `/tmp/camofox-state/<session>.tab`.

```bash
camofox open https://example.com
# → Opened: https://example.com
#   Tab: abc123
```

Equivalent:

```bash
curl -s -X POST "$BASE/tabs" \
  -H 'Content-Type: application/json' \
  -d '{"userId":"camofox-default","sessionKey":"default","url":"https://example.com"}'
```

### `camofox navigate <url>`

Navigate the currently active tab (stored ID).

```bash
camofox navigate https://example.com/page
```

Equivalent:

```bash
curl -s -X POST "$BASE/tabs/$TAB_ID/navigate" \
  -H 'Content-Type: application/json' \
  -d '{"userId":"'$USER_ID'","url":"https://example.com/page"}'
```

### `camofox back` | `forward` | `refresh`

```bash
camofox back
camofox forward
camofox refresh
```

Equivalent (each):

```bash
curl -s -X POST "$BASE/tabs/$TAB_ID/back" \
  -H 'Content-Type: application/json' \
  -d '{"userId":"'$USER_ID'"}'
```

### `camofox scroll [down|up|left|right]`

Default direction: `down`.

```bash
camofox scroll
camofox scroll up
```

Equivalent:

```bash
curl -s -X POST "$BASE/tabs/$TAB_ID/scroll" \
  -H 'Content-Type: application/json' \
  -d '{"userId":"'$USER_ID'","direction":"down"}'
```

---

## Page State

### `camofox snapshot`

Text representation of the accessibility tree with `@refs`.

```bash
camofox snapshot
# [button e1] Submit  [link e2] Learn more  [input e3] Email
#
# URL: https://example.com
```

Equivalent:

```bash
curl -s "$BASE/tabs/$TAB_ID/snapshot?userId=$USER_ID"
```

### `camofox screenshot [path]`

Default path: `/tmp/camofox-screenshots/camofox-YYYYMMDD-HHMMSS.png`.

```bash
camofox screenshot
camofox screenshot ./page.png
```

Equivalent:

```bash
curl -s -o ./page.png "$BASE/tabs/$TAB_ID/screenshot?userId=$USER_ID"
```

### `camofox tabs`

List open tabs for the current session.

```bash
camofox tabs
#   abc123  https://example.com
#   def456  https://google.com
```

Equivalent:

```bash
curl -s "$BASE/tabs?userId=$USER_ID"
```

### `camofox links`

All anchors on the current page.

```bash
camofox links
```

Equivalent:

```bash
curl -s "$BASE/tabs/$TAB_ID/links?userId=$USER_ID"
```

---

## Interaction

Pass refs with the `@` prefix — the wrapper strips it before sending.

### `camofox click @eN`

```bash
camofox click @e1
# → Clicked: @e1
```

Equivalent:

```bash
curl -s -X POST "$BASE/tabs/$TAB_ID/click" \
  -H 'Content-Type: application/json' \
  -d '{"userId":"'$USER_ID'","ref":"e1"}'
```

**Re-snapshot immediately** — the DOM may have changed.

### `camofox type @eN "text"`

```bash
camofox type @e3 "hello@example.com"
```

Equivalent:

```bash
curl -s -X POST "$BASE/tabs/$TAB_ID/type" \
  -H 'Content-Type: application/json' \
  -d '{"userId":"'$USER_ID'","ref":"e3","text":"hello@example.com"}'
```

---

## Search Macros

### `camofox search <name> "query"`

Short names auto-expand: `google` → `@google_search`.

```bash
camofox search google  "best coffee beans"
camofox search youtube "cooking tutorial"
```

If no active tab exists, one is created automatically.

Equivalent:

```bash
curl -s -X POST "$BASE/tabs/$TAB_ID/navigate" \
  -H 'Content-Type: application/json' \
  -d '{"userId":"'$USER_ID'","macro":"@google_search","query":"best coffee beans"}'
```

Full list of macros: [macros.md](macros.md).

---

## Cleanup

### `camofox close`

Closes the active tab and removes the state file.

```bash
camofox close
# → Closed tab: abc123
```

Equivalent:

```bash
curl -s -X DELETE "$BASE/tabs/$TAB_ID?userId=$USER_ID"
rm -f /tmp/camofox-state/${CAMOFOX_SESSION:-default}.tab
```

### `camofox close-all`

Close every tab for the current user.

```bash
camofox close-all
# → Closed all tabs for session: default
```

Equivalent:

```bash
curl -s -X DELETE "$BASE/sessions/$USER_ID"
```

---

## Global Flags

- `--session <name>` — override `CAMOFOX_SESSION` for this call only.
- `--port <port>` — override `CAMOFOX_PORT` for this call only (CLI mode; ignored if `CAMOFOX_URL` is set).

```bash
camofox --session work open https://mail.example.com
camofox --session work snapshot
```
