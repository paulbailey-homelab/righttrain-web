#!/usr/bin/env bash
# Guards the pieces that other systems depend on. Ported from the backend chart's
# public_ingress_test.go when the site moved to its own repository.
set -euo pipefail
cd "$(dirname "$0")/.."

fail() { echo "check-config: $*" >&2; exit 1; }

# nginx must serve the apple-app-site-association file as JSON.
for token in 'location = /.well-known/apple-app-site-association' 'default_type application/json'; do
  grep -qF "$token" nginx.conf || fail "nginx.conf missing AASA token: $token"
done

# The AASA file must be valid JSON and name the iOS app in both sections.
aasa=public/.well-known/apple-app-site-association
app_id="CV8JK3JKZX.com.righttrain.ios"
jq -e . "$aasa" >/dev/null || fail "$aasa is not valid JSON"
jq -e --arg id "$app_id" '.webcredentials.apps | index($id)' "$aasa" >/dev/null \
  || fail "AASA webcredentials missing $app_id"
jq -e --arg id "$app_id" '.applinks.details[0].appIDs | index($id)' "$aasa" >/dev/null \
  || fail "AASA applinks missing $app_id"

# The ingresses must route the configured API paths to the backend before the static site,
# and render extra hosts / certificate names.
grep -qF '.Values.ingress.apiPaths' deploy/helm/righttrain-web/templates/ingress.yaml \
  || fail "ingress must route configured API paths before the static site"
grep -qF '.Values.ingress.additionalHosts' deploy/helm/righttrain-web/templates/ingress.yaml \
  || fail "ingress must render configured additional hosts"
grep -qF '.Values.certificate.extraDnsNames' deploy/helm/righttrain-web/templates/certificate.yaml \
  || fail "certificate must render configured extra DNS names"

# Production values: the shared-journey API path and both public hosts.
values=deploy/homelab/values-homelab.yaml
defaults=deploy/helm/righttrain-web/values.yaml
grep -qF 'publicWebBaseUrl: https://righttrain.app' "$defaults" || fail "defaults missing publicWebBaseUrl"
grep -qF 'path: /v1/journey-shares' "$defaults" || fail "defaults missing the journey-shares API path"
grep -qF 'path: /v1/status' "$defaults" || fail "defaults missing the status API path"
grep -qF 'host: righttrain.app' "$values" || fail "production values missing the main host"
grep -qF 'host: status.righttrain.app' "$values" || fail "production values missing the status host"

echo "check-config: ok"
