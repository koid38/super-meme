#!/bin/sh
# Installs the game into the nginx web root as /istanbul/.
# Run on the server:
#   curl -fsSL https://raw.githubusercontent.com/koid38/super-meme/HEAD/istanbul/deploy.sh | sh
set -e

SRC="https://raw.githubusercontent.com/koid38/super-meme/HEAD/istanbul/index.html"
NAME="istanbul"

CONF_ROOT=""
if command -v nginx >/dev/null 2>&1; then
  CONF_ROOT=$(nginx -T 2>/dev/null | awk '$1 == "root" { sub(";", "", $2); print $2; exit }')
fi
ROOT=""
for d in "$CONF_ROOT" /var/www/html /usr/share/nginx/html; do
  if [ -n "$d" ] && [ -d "$d" ]; then ROOT=$d; break; fi
done
if [ -z "$ROOT" ]; then
  echo "Не нашёл папку сайта nginx (ни /var/www/html, ни /usr/share/nginx/html)." >&2
  exit 1
fi

TMP=$(mktemp)
if command -v curl >/dev/null 2>&1; then
  curl -fsSL "$SRC" -o "$TMP"
else
  wget -qO "$TMP" "$SRC"
fi
if [ ! -s "$TMP" ]; then
  echo "Не удалось скачать игру с GitHub." >&2
  rm -f "$TMP"
  exit 1
fi

mkdir -p "$ROOT/$NAME"
# cp (not mv) so the file takes the folder's permissions and SELinux label.
cp "$TMP" "$ROOT/$NAME/index.html"
rm -f "$TMP"
chmod 755 "$ROOT/$NAME"
chmod 644 "$ROOT/$NAME/index.html"
if command -v restorecon >/dev/null 2>&1; then restorecon -R "$ROOT/$NAME" || true; fi

echo "Готово: игра лежит в $ROOT/$NAME/"
echo "Откройте в браузере: http://<IP сервера>/$NAME/"
