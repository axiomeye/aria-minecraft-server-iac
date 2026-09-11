#!/bin/bash
# Welcome players when they join the Minecraft server.
set -uo pipefail

SERVER_NAME="${1:-AriA}"

echo "welcome_message: starting join listener for '$SERVER_NAME'..."

# Wait for container to appear
for _ in $(seq 1 60); do
  docker inspect mc >/dev/null 2>&1 && break
  sleep 5
done

if ! docker inspect mc >/dev/null 2>&1; then
  echo "welcome_message: container 'mc' never appeared; exiting" >&2
  exit 1
fi

# Wait until the container reports healthy / server is accepting connections
for _ in $(seq 1 120); do
  health=$(docker inspect -f '{{.State.Health.Status}}' mc 2>/dev/null || echo unknown)
  [ "$health" = "healthy" ] && break
  sleep 5
done

echo "welcome_message: server is ready, monitoring player joins..."

# Listen to server log output for player joins
docker logs -f --tail 0 mc 2>&1 | while read -r line; do
  if [[ "$line" =~ ([a-zA-Z0-9_]{3,16})\ joined\ the\ game ]] || [[ "$line" =~ ([a-zA-Z0-9_]{3,16})\[.*\]\ logged\ in ]]; then
    PLAYER="${BASH_REMATCH[1]}"
    # Brief pause so the player has finished world terrain loading
    sleep 2
    echo "welcome_message: welcoming player '$PLAYER' to $SERVER_NAME"
    docker exec mc rcon-cli title "$PLAYER" times 10 70 20 2>/dev/null || true
    docker exec mc rcon-cli title "$PLAYER" subtitle "{\"text\":\"$SERVER_NAME\",\"color\":\"gold\",\"bold\":true}" 2>/dev/null || true
    docker exec mc rcon-cli title "$PLAYER" title "{\"text\":\"Benvenuto in\",\"color\":\"yellow\"}" 2>/dev/null || true
    docker exec mc rcon-cli tellraw "$PLAYER" "[{\"text\":\"[AriA] \",\"color\":\"gold\",\"bold\":true},{\"text\":\"Benvenuto in \",\"color\":\"yellow\"},{\"text\":\"$SERVER_NAME\",\"color\":\"gold\",\"bold\":true},{\"text\":\"!\",\"color\":\"yellow\"}]" 2>/dev/null || true
  fi
done
