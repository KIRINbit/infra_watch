#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/.."
if command -v podman >/dev/null 2>&1; then
  RUNTIME="podman"; COMPOSE="podman compose"
elif command -v docker >/dev/null 2>&1; then
  RUNTIME="docker"; COMPOSE="docker compose"
else
  echo "Не найден контейнерный движок"; exit 1
fi
$COMPOSE logs -f "$@"
