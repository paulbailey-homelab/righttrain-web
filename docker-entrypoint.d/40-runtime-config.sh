#!/bin/sh
set -eu

: "${API_BASE_URL:=http://localhost:8080}"
: "${PUBLIC_WEB_BASE_URL:=https://righttrain.app}"
: "${RIGHTTRAIN_APP_STORE_URL:=}"

cat > /usr/share/nginx/html/runtime-config.js <<EOF
window.__RIGHTTRAIN_CONFIG__ = {
  apiBaseUrl: "${API_BASE_URL}",
  publicWebBaseUrl: "${PUBLIC_WEB_BASE_URL}",
  appStoreUrl: "${RIGHTTRAIN_APP_STORE_URL}"
};
EOF
