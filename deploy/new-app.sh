#!/usr/bin/env bash
# Sets up a new app on the server: deploy key, clone, .env, container, nginx, HTTPS.
# Run as the deploy user:  new-app.sh <app-name> <port>
#   <app-name> = GitHub repo name = subdomain (e.g. app1 -> app1.appnest.us)
#   <port>     = free local port for the container (8001, 8002, ...)
set -euo pipefail

GH_USER="${GH_USER:-fsahingh}"
DOMAIN="${DOMAIN:-appnest.us}"

NAME="${1:-}"
PORT="${2:-}"
if [[ ! "$NAME" =~ ^[a-z0-9-]+$ || ! "$PORT" =~ ^[0-9]+$ ]]; then
  echo "Kullanim: $0 <app-adi> <port>   (ornek: $0 app1 8001)"
  exit 1
fi

APP_DIR="/opt/apps/$NAME"
HOST="$NAME.$DOMAIN"
KEY="$HOME/.ssh/deploy_$NAME"
ALIAS="github-$NAME"

if [[ ! -d "$APP_DIR" ]] && ss -ltn | grep -q ":$PORT "; then
  echo "HATA: $PORT portu zaten kullaniliyor. Baska bir port sec."
  exit 1
fi

echo "==> 1/6 GitHub deploy key"
mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
[[ -f "$KEY" ]] || ssh-keygen -q -t ed25519 -N "" -C "appnest-server:$NAME" -f "$KEY"
if ! grep -q "^Host $ALIAS\$" "$HOME/.ssh/config" 2>/dev/null; then
  printf 'Host %s\n  HostName github.com\n  User git\n  IdentityFile %s\n  IdentitiesOnly yes\n\n' "$ALIAS" "$KEY" >> "$HOME/.ssh/config"
  chmod 600 "$HOME/.ssh/config"
fi
grep -q "^github.com " "$HOME/.ssh/known_hosts" 2>/dev/null || ssh-keyscan -t ed25519 github.com >> "$HOME/.ssh/known_hosts" 2>/dev/null

if [[ ! -d "$APP_DIR/.git" ]]; then
  echo
  echo "Bu anahtari GitHub'a ekle:"
  echo "  https://github.com/$GH_USER/$NAME/settings/keys  ->  Add deploy key"
  echo "  Title: appnest-server   (Allow write access: ISARETLEME)"
  echo
  cat "$KEY.pub"
  echo
  read -rp "Ekledikten sonra Enter'a bas... "
fi

echo "==> 2/6 Kod: $APP_DIR"
sudo mkdir -p /opt/apps && sudo chown "$USER:$USER" /opt/apps
if [[ -d "$APP_DIR/.git" ]]; then
  git -C "$APP_DIR" pull --ff-only
else
  git clone "git@$ALIAS:$GH_USER/$NAME.git" "$APP_DIR"
fi

echo "==> 3/6 .env"
if [[ ! -f "$APP_DIR/.env" ]]; then
  printf 'APP_PORT=%s\nAPP_NAME=%s\n' "$PORT" "$NAME" > "$APP_DIR/.env"
fi
grep -q "^APP_PORT=" "$APP_DIR/.env" || echo "APP_PORT=$PORT" >> "$APP_DIR/.env"
PORT="$(grep '^APP_PORT=' "$APP_DIR/.env" | cut -d= -f2)"

echo "==> 4/6 Konteyner"
(cd "$APP_DIR" && docker compose up -d --build)

echo "==> 5/6 nginx: $HOST -> 127.0.0.1:$PORT"
if [[ ! -f "/etc/nginx/sites-available/$NAME" ]]; then
  sudo tee "/etc/nginx/sites-available/$NAME" > /dev/null <<NGINX
server {
    listen 80;
    listen [::]:80;
    server_name $HOST;

    client_max_body_size 20m;

    location / {
        proxy_pass http://127.0.0.1:$PORT;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
NGINX
  sudo ln -sf "/etc/nginx/sites-available/$NAME" "/etc/nginx/sites-enabled/$NAME"
fi
sudo nginx -t
sudo systemctl reload nginx

echo "==> 6/6 HTTPS sertifikasi"
sudo certbot --nginx -d "$HOST" --redirect --non-interactive --keep-until-expiring

echo
echo "TAMAM: https://$HOST"
