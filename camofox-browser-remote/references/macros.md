# Search Macros

Macros are server-side recipes that translate a short name + query into a fully-formed search URL for a target site. They work in remote mode because they're part of the upstream server.

## Available Macros (13)

| Macro | Short name | URL pattern |
|---|---|---|
| `@google_search` | `google` | `https://www.google.com/search?q=...` |
| `@youtube_search` | `youtube` | `https://www.youtube.com/results?search_query=...` |
| `@amazon_search` | `amazon` | `https://www.amazon.com/s?k=...` |
| `@reddit_search` | `reddit` | `https://www.reddit.com/search/?q=...` |
| `@wikipedia_search` | `wikipedia` | `https://en.wikipedia.org/w/index.php?search=...` |
| `@twitter_search` | `twitter` | `https://twitter.com/search?q=...` |
| `@yelp_search` | `yelp` | `https://www.yelp.com/search?find_desc=...` |
| `@spotify_search` | `spotify` | `https://open.spotify.com/search/...` |
| `@netflix_search` | `netflix` | `https://www.netflix.com/search?q=...` |
| `@linkedin_search` | `linkedin` | `https://www.linkedin.com/search/results/all/?keywords=...` |
| `@instagram_search` | `instagram` | `https://www.instagram.com/explore/tags/...` |
| `@tiktok_search` | `tiktok` | `https://www.tiktok.com/search?q=...` |
| `@twitch_search` | `twitch` | `https://www.twitch.tv/search?term=...` |

## Usage

### Via CLI (short name — auto-expanded)

```bash
camofox-remote search google  "best coffee beans"
camofox-remote search youtube "cooking tutorial"
camofox-remote search amazon  "wireless headphones"
```

### Via CLI (full macro name)

```bash
camofox-remote search @google_search "best coffee beans"
```

### Via raw API

```bash
curl -s -X POST "$CAMOFOX_URL/tabs/$TAB_ID/navigate" \
  -H 'Content-Type: application/json' \
  -d '{
    "userId": "camofox-default",
    "macro":  "@google_search",
    "query":  "best coffee beans"
  }'
```

## Typical Workflow

```bash
camofox-remote search google "site:github.com camoufox"
camofox-remote snapshot
# → @e1 [link] "Result 1"  @e2 [link] "Result 2" ...

camofox-remote click @e1
camofox-remote snapshot                   # MUST re-snapshot after navigation
```

## Notes

- Macros navigate the **active tab** (or create one if none exists).
- Results load through the full anti-detection stack — no special handling needed.
- Some sites (Netflix, Spotify) require authentication to show results; cookie import is supported via the upstream `/sessions/:userId/cookies` endpoint (not wrapped in this skill's CLI).
