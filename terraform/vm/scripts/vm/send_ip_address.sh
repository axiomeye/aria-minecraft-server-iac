#!/bin/bash
# Ask the send-ip-address workflow to publish this world's external IP.
#
# Inlined into the instance startup script by Terraform (see main.tf) and
# written to /opt/scripts at boot. This repository is the only source of truth;
# there is no bucket copy and nothing to upload after an edit.
#
# The dispatch token comes from Secret Manager, not from this file. The VM's
# service account (aria-server-sa) holds roles/secretmanager.secretAccessor.

set -uo pipefail

META="http://metadata.google.internal/computeMetadata/v1/instance/attributes"

# The workflow reads Terraform state to find the IP, and each world has its own
# state, so it must be told which world is asking.
WORLD=$(curl -s -H "Metadata-Flavor: Google" "$META/world" 2>/dev/null)
WORLD=${WORLD:-classic}

TOKEN=$(gcloud secrets versions access latest --secret=gh-dispatch-token 2>/dev/null)
if [ -z "$TOKEN" ]; then
  echo "send_ip_address: cannot read gh-dispatch-token from Secret Manager" >&2
  exit 1
fi

curl --request POST \
  --url 'https://api.github.com/repos/axiomeye/aria-minecraft-server-iac/dispatches' \
  --header "authorization: Bearer $TOKEN" \
  --header 'content-type: application/json' \
  --data "{\"event_type\": \"send-ip-address\", \"client_payload\": {\"world\": \"$WORLD\"}}"
