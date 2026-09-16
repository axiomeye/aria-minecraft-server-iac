#!/bin/bash
# Announce a Spot preemption the moment Google decides on it.
#
# Preemption is otherwise completely silent: the VM is deleted outright
# (instance_termination_action=DELETE), so the destroy workflow never runs and
# none of its Telegram messages fire. On 2026-09-16 the cobblemon VM vanished
# an hour into a session and the first anyone knew was a player getting a
# getsockopt error.
#
# Doing this from the shutdown script instead does not work reliably. When that
# VM was reclaimed, every log line stopped inside the same second that systemd
# began tearing down units, with nothing from google-shutdown-scripts -- the
# ~30s Google promises is shared with systemd stopping everything, and the Ops
# Agent goes with it. Here we instead block on the metadata server's
# wait_for_change, which returns as soon as the preempted flag flips, while the
# machine is still fully up and has working network. shutdown.sh stays as the
# clean world save, and does not notify, so there is exactly one notifier.
#
# Inlined into the startup script by Terraform (see main.tf) and written to
# /opt/scripts at boot; this repository is the only source of truth. The
# dispatch token comes from Secret Manager -- the VM's service account
# (aria-server-sa) holds roles/secretmanager.secretAccessor.

set -uo pipefail

MDS="http://metadata.google.internal/computeMetadata/v1/instance"
HDR="Metadata-Flavor: Google"

WORLD=$(curl -s -m 5 -H "$HDR" "$MDS/attributes/world" 2>/dev/null)
WORLD=${WORLD:-classic}

# Already preempted before we even started watching? Then fall straight through.
ETAG=""
while true; do
  # wait_for_change blocks until the value changes or timeout_sec elapses, so
  # this loop costs nothing while the VM is healthy. The etag makes the next
  # call resume from the state we last saw rather than returning immediately.
  RESP=$(curl -s -i -m 3600 -H "$HDR" \
    "$MDS/preempted?wait_for_change=true&timeout_sec=3000&last_etag=$ETAG" 2>/dev/null)

  # A non-response (metadata hiccup, network blip) should not spin the loop.
  if [ -z "$RESP" ]; then
    sleep 5
    continue
  fi

  NEW_ETAG=$(printf '%s' "$RESP" | grep -i '^etag:' | tail -1 | tr -d '\r' | awk '{print $2}')
  [ -n "$NEW_ETAG" ] && ETAG="$NEW_ETAG"

  VALUE=$(printf '%s' "$RESP" | tr -d '\r' | tail -1 | tr -d '[:space:]')
  [ "$VALUE" = "TRUE" ] && break
done

TOKEN=$(timeout 10 gcloud secrets versions access latest \
          --secret=gh-dispatch-token 2>/dev/null)
if [ -z "$TOKEN" ]; then
  echo "watch_preemption: cannot read gh-dispatch-token from Secret Manager" >&2
  exit 1
fi

curl -s -m 10 --request POST \
  --url 'https://api.github.com/repos/axiomeye/aria-minecraft-server-iac/dispatches' \
  --header "authorization: Bearer $TOKEN" \
  --header 'content-type: application/json' \
  --data "{\"event_type\": \"preempted\", \"client_payload\": {\"world\": \"$WORLD\"}}"
