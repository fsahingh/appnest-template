#!/usr/bin/env bash
# Refreshes the static pages and the appnest logo files on the server:
#   appnest.us       -> /var/www/appnest  (landing page, privacy policy)
#   apps.appnest.us  -> /var/www/apps     (apps panel)
# Run as the deploy user:
#   bash <(curl -fsSL https://raw.githubusercontent.com/fsahingh/appnest-template/main/deploy/update-pages.sh)
set -euo pipefail

RAW="https://raw.githubusercontent.com/fsahingh/appnest-template/main"
BRAND="favicon.svg favicon-32.png favicon.ico apple-touch-icon.png icon-192.png icon-512.png site.webmanifest"

get() { sudo curl -fsSL "$RAW/$1" -o "$2"; }

for dir in /var/www/appnest /var/www/apps; do
  sudo mkdir -p "$dir"
  for f in $BRAND; do get "brand/$f" "$dir/$f"; done
done
get landing/index.html   /var/www/appnest/index.html
get landing/privacy.html /var/www/appnest/privacy.html
get dashboard/index.html /var/www/apps/index.html
echo "TAMAM: appnest.us ve apps.appnest.us guncellendi"
