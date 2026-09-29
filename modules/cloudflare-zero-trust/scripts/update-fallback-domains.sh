#!/bin/bash
set -euo pipefail

# Values come in via environment (set by the local-exec provisioner's
# "environment" block), not positional args — avoids shell-quoting breakage
# from special characters (quotes, apostrophes, etc.) in the JSON payload.

for var in CF_ACCOUNT_ID CF_POLICY_ID CF_PAYLOAD CLOUDFLARE_API_TOKEN; do
  if [[ -z "${!var:-}" ]]; then
    echo "Error: ${var} environment variable must be set." >&2
    exit 1
  fi
done

curl -sS --fail-with-body -X PUT \
  "https://api.cloudflare.com/client/v4/accounts/${CF_ACCOUNT_ID}/devices/policy/${CF_POLICY_ID}/fallback_domains" \
  -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "${CF_PAYLOAD}"
