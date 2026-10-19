#!/usr/bin/env bash
# Daily backup of every app's SQLite database (/opt/apps/<app>, the file named by DB_PATH in its container).
# Copies it with SQLite's backup API inside the running container (safe while the app is in use),
# checks the copy, then gzips it to ~/backups/<app>/<app>-YYYY-MM-DD.db.gz and keeps KEEP_DAYS days.
# Run as the deploy user (cron runs it every night, see README).
set -uo pipefail

DEST="${BACKUP_DIR:-$HOME/backups}"
KEEP_DAYS="${KEEP_DAYS:-30}"
DAY="$(date +%F)"
failed=0

for dir in /opt/apps/*/; do
  app="$(basename "$dir")"
  [[ -f "$dir/docker-compose.yml" ]] || continue
  cd "$dir" || continue
  mkdir -p "$DEST/$app"
  out="$DEST/$app/$app-$DAY.db"
  # copy + integrity check inside the container; prints "ok" only when the copy is sound
  check="$(docker compose exec -T web python - 2>&1 <<'PY'
import os, sqlite3
src = sqlite3.connect(os.environ["DB_PATH"])
dst = sqlite3.connect("/tmp/backup.db")
src.backup(dst)
src.close()
print(dst.execute("PRAGMA integrity_check").fetchone()[0])
dst.close()
PY
)"
  if [[ "$check" == "ok" ]] && docker compose cp web:/tmp/backup.db "$out" >/dev/null 2>&1 && gzip -f "$out"; then
    echo "$(date '+%F %T') $app: ok $(du -h "$out.gz" | cut -f1)"
  else
    echo "$(date '+%F %T') $app: FAILED ${check:0:200}"
    rm -f "$out"
    failed=1
  fi
  docker compose exec -T web rm -f /tmp/backup.db >/dev/null 2>&1
done

find "$DEST" -name '*.db.gz' -mtime +"$KEEP_DAYS" -delete
exit $failed
