#!/bin/bash
# Notify that this world's server container exited before becoming healthy,
# instead of silently waiting out the health-check timeout and then either
# announcing a dead IP or self-destroying with no explanation.
#
# Inlined into the instance startup script by Terraform (see main.tf) and
# written to /opt/scripts at boot. This repository is the only source of truth;
# there is no bucket copy and nothing to upload after an edit.
#
# The dispatch token comes from Secret Manager, not from this file. The VM's
# service account (aria-server-sa) holds roles/secretmanager.secretAccessor.
#
# Deliberately does NOT go through Terraform, unlike send_ip_address.sh: there
# is no IP to report, and a terraform apply here would only add exposure to
# the same state-lock contention that made send-ip-address fail outright when
# it raced destroy-infr on 2026-09-13. report-boot-failure's workflow just
# posts to Telegram, no state touched.

set -uo pipefail

META="http://metadata.google.internal/computeMetadata/v1/instance/attributes"
WORLD=$(curl -s -H "Metadata-Flavor: Google" "$META/world" 2>/dev/null)
WORLD=${WORLD:-classic}

# Caller passes an already-JSON-safe single-line reason (backslashes/quotes
# escaped, newlines replaced) -- see config.sh.tftpl's crash branch.
REASON="${1:-no details captured}"

TOKEN=$(gcloud secrets versions access latest --secret=gh-dispatch-token 2>/dev/null)
if [ -z "$TOKEN" ]; then
  echo "report_boot_failure: cannot read gh-dispatch-token from Secret Manager" >&2
  exit 1
fi

curl --request POST \
  --url 'https://api.github.com/repos/axiomeye/aria-minecraft-server-iac/dispatches' \
  --header "authorization: Bearer $TOKEN" \
  --header 'content-type: application/json' \
  --data "{\"event_type\": \"boot-failed\", \"client_payload\": {\"world\": \"$WORLD\", \"reason\": \"$REASON\"}}"
