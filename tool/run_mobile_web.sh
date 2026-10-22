#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WEB_PORT="${WEB_PORT:-5173}"
API_PORT="${API_PORT:-8080}"
MAC_IP="${MAC_IP:-$(ipconfig getifaddr en0 2>/dev/null || true)}"

if [[ -z "$MAC_IP" ]]; then
  echo "Could not find the Mac Wi-Fi address. Run with MAC_IP=192.168.x.x $0"
  exit 1
fi

cleanup() {
  if [[ -n "${API_PID:-}" ]]; then
    kill "$API_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT INT TERM

cd "$PROJECT_DIR"
python3 server/server.py \
  --host 0.0.0.0 \
  --port "$API_PORT" \
  --allowed-origins "http://$MAC_IP:$WEB_PORT" &
API_PID=$!

echo "Opening BayouBlitz to phones on this Wi-Fi: http://$MAC_IP:$WEB_PORT"
echo "API health check: http://$MAC_IP:$API_PORT/health"

flutter run -d web-server \
  --web-hostname 0.0.0.0 \
  --web-port "$WEB_PORT" \
  --dart-define="TAILGATE_API_URL=http://$MAC_IP:$API_PORT"
