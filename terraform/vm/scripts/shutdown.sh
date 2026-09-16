#!/bin/bash
# Runs on any instance shutdown, including Spot preemption.
#
# Preemption is otherwise completely silent: Google reclaims the VM, the
# instance_termination_action=DELETE setting removes it outright, and nobody
# runs the destroy workflow -- so none of the usual Telegram messages fire and
# players just see a dropped connection. (Happened 2026-09-16: the cobblemon
# VM was preempted an hour after boot and the first anyone knew was a friend
# getting a getsockopt error.) So notify first, then stop the server.
#
# Order matters: GCE only guarantees ~30s for this script on a preempted Spot
# instance, and `rcon-cli stop` blocks on a full world save, which can eat most
# of it. Dispatch before saving, and cap the notify path so a slow metadata or
# Secret Manager call cannot starve the save.

META="http://metadata.google.internal/computeMetadata/v1/instance/attributes"
MDS="http://metadata.google.internal/computeMetadata/v1/instance"

# Only announce genuine preemptions. A normal destroy already posts its own
# Telegram messages from the workflow, and duplicating them here would mean two
# notifications for every ordinary shutdown.
PREEMPTED=$(curl -s -m 3 -H "Metadata-Flavor: Google" "$MDS/preempted" 2>/dev/null)

if [ "$PREEMPTED" = "TRUE" ]; then
  (
    WORLD=$(curl -s -m 3 -H "Metadata-Flavor: Google" "$META/world" 2>/dev/null)
    WORLD=${WORLD:-classic}
    TOKEN=$(timeout 8 gcloud secrets versions access latest \
              --secret=gh-dispatch-token 2>/dev/null)
    if [ -n "$TOKEN" ]; then
      curl -s -m 8 --request POST \
        --url 'https://api.github.com/repos/axiomeye/aria-minecraft-server-iac/dispatches' \
        --header "authorization: Bearer $TOKEN" \
        --header 'content-type: application/json' \
        --data "{\"event_type\": \"preempted\", \"client_payload\": {\"world\": \"$WORLD\"}}"
    fi
  ) &
fi

# Stop the server cleanly so the world is saved before the disk detaches.
sudo docker exec mc rcon-cli stop

wait
