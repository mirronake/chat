#!/bin/sh
set -e

# Start YouTube WebSocket service in background
cd /app/youtube-websocket
bun run src/index.ts &

# Start Go backend
cd /app
exec ./chat :1535
