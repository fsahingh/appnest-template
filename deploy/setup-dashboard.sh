#!/usr/bin/env bash
# Installs / updates the apps dashboard at https://apps.appnest.us (static page behind Cloudflare Access).
# Run as the deploy user. Safe to re-run: it only refreshes the page if nginx is already set up.
set -euo pipefail

HOST="apps.appnest.us"
ROOT="/var/www/apps"
CF_DIR=/etc/ssl/cloudflare
SRC="https://raw.githubusercontent.com/fsahingh/appnest-template/main/dashboard/index.html"

sudo mkdir -p "$ROOT"
sudo curl -fsSL "$SRC" -o "$ROOT/index.html"
echo "==> Page updated: $ROOT/index.html"

if [[ ! -f /etc/nginx/sites-available/apps ]]; then
  sudo tee /etc/nginx/sites-available/apps > /dev/null <<NGINX
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name $HOST;

    ssl_certificate         $CF_DIR/appnest-origin.pem;
    ssl_certificate_key     $CF_DIR/appnest-origin.key;
    ssl_client_certificate  $CF_DIR/origin-pull-ca.pem;
    ssl_verify_client       on;

    root $ROOT;
    index index.html;
    add_header Cache-Control "no-cache";

    location / {
        try_files \$uri \$uri/ =404;
    }
}
NGINX
  sudo ln -sf /etc/nginx/sites-available/apps /etc/nginx/sites-enabled/apps
  echo "==> nginx site created"
fi

sudo nginx -t
sudo systemctl reload nginx
echo "TAMAM: https://$HOST"
