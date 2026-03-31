# Cyan Chat – Project Guidelines

Cyan Chat is a Twitch (+ optional YouTube) chat overlay for OBS/streaming software, forked from JChat. It consists of three components:

- **Go backend** (`main.go`) – single-file HTTP server
- **Frontend v2** (`src/v2/`) – jQuery-based browser overlay (plain JS, no build step)
- **Frontend Config Page** (`src/`) - Page to customize the look and functions of the chat overlay.
- **YouTube WebSocket service** (`youtube-websocket/`) – separate Bun/Elysia server

## Architecture

```
browser overlay (src/v2/)
    ↕ Twitch IRC WebSocket (direct)
    ↕ YouTube WS via Go relay (/ws → localhost:9905)

config page (src/)
      ↕ The user configures settings here, which are passed to the overlay via URL query parameters (e.g. ?animate=1&center=1&size=24)

Go backend (main.go, port :1535)
    → serves dist/ (webpack-built legacy src/)
    → proxies Twitch Helix API at /twitch/*
    → relays YouTube WebSocket at /ws
    → TTS via AWS Polly at /api/tts
    → Twitch EventSub SSE for Shared Chat at /api/shared-chat/*
    → admin panel at /admin/active

YouTube WebSocket service (youtube-websocket/, port 9905)
    /c/:id  – channel WebSocket (live chat)
    /s/:id  – stream WebSocket
```

**Runtime config files** (must exist before running):

- `tokens.json` – Twitch OAuth tokens, client ID/secret, admin password
- `active.json` – auto-created; tracks recently active channels

## Build & Run

```bash
# Frontend (webpack → dist/)
npm run build           # or: pack.bat

# Go backend
compile.bat             # builds chat.exe (Windows) + chat (Linux)
run.bat                 # runs: chat.exe :1535 local

# YouTube WS service (uses Bun)
cd youtube-websocket
bun run src/index.ts    # start server
bun run testchannel     # run channel tests
bun run teststream      # run stream tests
```

## Conventions

### Frontend (src/v2/)

- All user settings are **URL query parameters** – never cookies or localStorage. See `src/v2/script.js` for the full list (`animate`, `center`, `sms`, `bots`, `hide_commands`, `fade`, `size`, `font`, `stroke`, `shadow`, etc.).
- Visual variants (font, size, weight, height, stroke, shadow) are applied by **dynamically loading CSS files** from `src/v2/styles/`. The available option arrays are defined in `src/v2/settings.js`.
- Plain JS + jQuery only – no TypeScript, no bundler for v2.
- Emote sources: 7TV (with live WebSocket updates via `src/v2/sevenWS.js`), BTTV, FFZ.

### Config page (src/)

- Also plain JS + jQuery, no build step.
- Settings are saved to `localStorage` and passed to the overlay via URL query parameters (e.g. `?animate=1&center=1&size=24`).

### Go backend

- All logic lives in `main.go` (single-file pattern – keep it that way unless there's a strong reason to split).
- Tokens are loaded from `tokens.json` at startup via `loadTokens()`. The Twitch access token auto-refreshes every 120 min via `refreshTokenLoop()`.
- Origin check (`isRequestFromYourWebsite`) gates `/ws` and `/api/tts` – do not remove this.
- Shared Chat uses Twitch EventSub WebSocket → SSE fan-out. Debug logs are prefixed `[TEMP DEBUG][SharedChat]` – these should be cleaned up before production.

### YouTube WebSocket service

- TypeScript + Bun + Elysia framework.
- Source in `youtube-websocket/src/`, tests in `youtube-websocket/test/`.
- Runs on port `9905` (matches the Go relay `ws://localhost:9905/c/`).

## Key Files

| File                             | Purpose                                |
| -------------------------------- | -------------------------------------- |
| `main.go`                        | Entire Go backend                      |
| `src/v2/script.js`               | Chat rendering & IRC connection        |
| `src/v2/settings.js`             | Option arrays (fonts, sizes, weights…) |
| `src/v2/sevenWS.js`              | 7TV live emote WebSocket               |
| `src/v2/syncEmotes.js`           | Emote fetching (7TV, BTTV, FFZ)        |
| `src/v2/styles/style.css`        | Base overlay styles                    |
| `src/script.js`                  | Config page logic                      |
| `src/style.css`                  | Config page styles                     |
| `youtube-websocket/src/index.ts` | Bun/Elysia entrypoint                  |
| `tokens.json`                    | Runtime secrets (not committed)        |
