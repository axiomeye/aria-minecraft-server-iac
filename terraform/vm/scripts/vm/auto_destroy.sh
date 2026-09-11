#!/bin/bash
# Destroy this world's VM once the Minecraft server stops itself.
#
# Inlined into the instance startup script by Terraform (see main.tf) and
# written to /opt/scripts at boot. This repository is the only source of truth;
# there is no bucket copy and nothing to upload after an edit.
#
# The dispatch token comes from Secret Manager, not from this file. The VM's
# service account (aria-server-sa) holds roles/secretmanager.secretAccessor.
#
# This waits for the container to exit rather than watching load average. The
# container is configured with ENABLE_AUTOSTOP, which counts connected players
# and stops the server after AUTOSTOP_TIMEOUT_EST seconds with none (and gives
# AUTOSTOP_TIMEOUT_INIT seconds for the first player to join).
#
# The previous version compared the 5 minute load average against 0.10. That is
# not a usable proxy for "nobody is playing": a modded server with a player
# connected but idle sits below that threshold, and on 2026-09-11 it destroyed
# the cobblemon VM out from under a connected player. Player count is the only
# signal that actually means what we want.

set -uo pipefail

META="http://metadata.google.internal/computeMetadata/v1/instance/attributes"

# Which world this VM is. Set as instance metadata by Terraform. Without it the
# dispatch would default to classic, and e.g. the cobblemon VM would destroy the
# classic world instead of itself.
WORLD=$(curl -s -H "Metadata-Flavor: Google" "$META/world" 2>/dev/null)
WORLD=${WORLD:-classic}

TOKEN=$(gcloud secrets versions access latest --secret=gh-dispatch-token 2>/dev/null)
if [ -z "$TOKEN" ]; then
  echo "auto_destroy: cannot read gh-dispatch-token from Secret Manager; not arming" >&2
  exit 1
fi

# Block until the server container exits. If it is not up yet, wait for it to
# appear first, so a slow start is never mistaken for a stopped server.
for _ in $(seq 1 60); do
  docker inspect mc >/dev/null 2>&1 && break
  sleep 10
done
if ! docker inspect mc >/dev/null 2>&1; then
  echo "auto_destroy: container 'mc' never appeared; not arming" >&2
  exit 1
fi

echo "auto_destroy: watching container 'mc' for world '$WORLD'"
docker wait mc >/dev/null 2>&1
echo "auto_destroy: container exited, requesting destroy of world '$WORLD'"

curl --request POST \
  --url 'https://api.github.com/repos/axiomeye/aria-minecraft-server-iac/dispatches' \
  --header "authorization: Bearer $TOKEN" \
  --header 'content-type: application/json' \
  --data "{\"event_type\": \"destroy-infr\", \"client_payload\": {\"world\": \"$WORLD\"}}"
