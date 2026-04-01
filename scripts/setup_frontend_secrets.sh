#!/bin/bash
# Run this once to populate all GitHub environment secrets/variables needed
# by the deploy_frontend workflow.
#
# Prerequisites:
#   - gh CLI installed and authenticated (gh auth login)
#   - You have write access to the repo
#
# Usage: bash scripts/setup_frontend_secrets.sh

set -euo pipefail

REPO="axiomeye/aria-minecraft-server-iac"
ENV="aria-production"

echo "Setting up frontend secrets for $REPO / environment: $ENV"
echo ""

# Flask secret key -------------------------------------------------------
read -rsp "Flask secret key (leave blank to auto-generate): " FLASK_KEY; echo
if [ -z "$FLASK_KEY" ]; then
  FLASK_KEY=$(openssl rand -hex 32)
  echo "  Auto-generated."
fi
gh secret set FRONTEND_FLASK_SECRET --env "$ENV" --repo "$REPO" --body "$FLASK_KEY"
echo "  FRONTEND_FLASK_SECRET set."

# Google OAuth credentials -----------------------------------------------
echo ""
echo "Create an OAuth 2.0 Client ID at:"
echo "  GCP Console > APIs & Services > Credentials > Create credentials > OAuth client ID"
echo "  Application type: Web application"
echo "  Authorised redirect URI: https://<cloud-run-url>/auth/callback"
echo "  (You can add the redirect URI after the first deploy once you know the URL)"
echo ""
read -rsp "Google OAuth Client ID: " OAUTH_ID; echo
gh secret set FRONTEND_OAUTH_CLIENT_ID --env "$ENV" --repo "$REPO" --body "$OAUTH_ID"
echo "  FRONTEND_OAUTH_CLIENT_ID set."

read -rsp "Google OAuth Client Secret: " OAUTH_SECRET; echo
gh secret set FRONTEND_OAUTH_CLIENT_SECRET --env "$ENV" --repo "$REPO" --body "$OAUTH_SECRET"
echo "  FRONTEND_OAUTH_CLIENT_SECRET set."

# GitHub App credentials (already set via gcloud/gh — skip if done)
# GH_APP_ID, GH_APP_INSTALLATION_ID, GH_APP_PRIVATE_KEY are set separately.

# Allowed emails (variable, not secret) ----------------------------------
echo ""
read -rp "Allowed Google emails (comma-separated, e.g. a@gmail.com,b@gmail.com): " EMAILS
gh variable set FRONTEND_ALLOWED_EMAILS --env "$ENV" --repo "$REPO" --body "$EMAILS"
echo "  FRONTEND_ALLOWED_EMAILS set."

echo ""
echo "All done. Push a change to frontend/ to trigger the first deploy."
echo "After the first deploy, add the Cloud Run URL as an OAuth redirect URI."
