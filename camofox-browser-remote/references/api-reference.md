# REST API Reference

Base URL: `$CAMOFOX_URL` (required env var — e.g. `http://172.17.0.1:9377`). This page uses `$BASE` as a placeholder — substitute your `CAMOFOX_URL` value.

All request bodies are `application/json`. Responses are JSON unless noted (screenshot returns `image/png`).

---

## GET /health

Liveness probe.

```bash
curl -s "$BASE/health"
# → {"ok":true,"engine":"camoufox","browserConnected":true,...}
```

Run this first when a command fails — see [troubleshooting.md](troubleshooting.md).

---

## POST /tabs

Create a new browser tab, optionally navigating immediately.

Body:

```json
{
  "userId": "camofox-default",
  "sessionKey": "default",
  "url": "https://example.com"
}
```

Response:

```json
{ "tabId": "abc123", "url": "https://example.com" }
```

- `userId` isolates the browser context (cookies, storage).
- `sessionKey` groups tabs within a user.
- `url` is optional; if omitted, the tab is created blank.

---

## GET /tabs?userId=X

List all open tabs for a user.

```bash
curl -s "$BASE/tabs?userId=camofox-default"
# → [{"tabId":"abc123","url":"https://example.com"}, ...]
```

---

## DELETE /tabs/:tabId?userId=X

Close one tab.

```bash
curl -X DELETE "$BASE/tabs/abc123?userId=camofox-default"
```

---

## DELETE /sessions/:userId

Close every tab in a user's session.

```bash
curl -X DELETE "$BASE/sessions/camofox-default"
```

---

## POST /tabs/:tabId/navigate

Navigate to a URL or trigger a search macro.

**URL form:**

```json
{ "userId": "camofox-default", "url": "https://example.com" }
```

**Macro form** (see [macros.md](macros.md)):

```json
{ "userId": "camofox-default", "macro": "@google_search", "query": "best coffee beans" }
```

---

## GET /tabs/:tabId/snapshot?userId=X

Accessibility snapshot with stable element refs.

Response:

```json
{
  "snapshot": "[button e1] Submit  [link e2] Learn more  [input e3] Email",
  "refs": {
    "e1": {"role": "button", "name": "Submit"},
    "e2": {"role": "link",   "name": "Learn more"},
    "e3": {"role": "textbox","name": "Email"}
  },
  "url": "https://example.com"
}
```

Refs (`e1`, `e2`, …) are invalidated when the DOM changes. Send the bare ref (no `@` prefix) back to the server — the `@` is a CLI-only convention.

---

## POST /tabs/:tabId/click

```json
{ "userId": "camofox-default", "ref": "e1" }
```

---

## POST /tabs/:tabId/type

```json
{ "userId": "camofox-default", "ref": "e3", "text": "hello@example.com" }
```

---

## POST /tabs/:tabId/scroll

```json
{ "userId": "camofox-default", "direction": "down" }
```

Directions: `down`, `up`, `left`, `right`.

---

## POST /tabs/:tabId/back | /forward | /refresh

```json
{ "userId": "camofox-default" }
```

---

## GET /tabs/:tabId/links?userId=X

Every anchor on the page, deduplicated.

```bash
curl -s "$BASE/tabs/abc123/links?userId=camofox-default"
```

---

## GET /tabs/:tabId/screenshot?userId=X

Returns **raw PNG bytes**, not JSON. Always use `curl -o`:

```bash
curl -s -o page.png "$BASE/tabs/abc123/screenshot?userId=camofox-default"
```

---

## Session Architecture

```
Browser (single, shared process)
└── BrowserContext  (per userId — isolated cookies/storage)
    ├── Tab group (sessionKey="conv1")
    │   ├── Tab (google.com)
    │   └── Tab (github.com)
    └── Tab group (sessionKey="conv2")
        └── Tab (amazon.com)
```

- One browser instance serves all users.
- Each `userId` owns an isolated context.
- Tabs within a user are grouped by `sessionKey`.
- 30-minute idle timeout by default; auto-cleanup.
