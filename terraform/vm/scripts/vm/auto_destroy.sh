#!/bin/bash
# Auto-destroy this world's VM once it goes idle.
#
# Inlined into the instance startup script by Terraform (see main.tf) and
# written to /opt/scripts at boot. This repository is the only source of truth;
# there is no bucket copy and nothing to upload after an edit.
#
# The dispatch token comes from Secret Manager, not from this file. The VM's
# service account (aria-server-sa) holds roles/secretmanager.secretAccessor.

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

while sleep 5; do
  load5M=$(uptime | awk -F'[a-z]:' '{ print $2}' | cut -d, -f1)
  threshold=0.10
  if (($(echo "$load5M <= $threshold" | bc -l))); then
    curl --request POST \
      --url 'https://api.github.com/repos/axiomeye/aria-minecraft-server-iac/dispatches' \
      --header "authorization: Bearer $TOKEN" \
      --header 'content-type: application/json' \
      --data "{\"event_type\": \"destroy-infr\", \"client_payload\": {\"world\": \"$WORLD\"}}"
    break
  fi
done
