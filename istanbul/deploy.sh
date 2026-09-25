#!/bin/sh
# Installs the game on this server's nginx as /istanbul/ and checks that it opens.
# Run on the server as root:
#   curl -fsSL https://raw.githubusercontent.com/koid38/super-meme/HEAD/istanbul/deploy.sh | sh
set -e

SRC="https://raw.githubusercontent.com/koid38/super-meme/HEAD/istanbul/index.html"
NAME="istanbul"

if [ "$(id -u)" != 0 ]; then
  echo "Нужны права root. Запустите так: curl -fsSL <та же ссылка> | sudo sh" >&2
  exit 1
fi

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

# The bare address shows nginx's welcome page; send visitors to the game
# unless the site already has its own start page.
if [ ! -e "$ROOT/index.html" ]; then
  printf '<!doctype html><meta charset="utf-8"><meta http-equiv="refresh" content="0; url=/%s/"><title>Изразцы Стамбула</title><a href="/%s/">Открыть игру</a>\n' "$NAME" "$NAME" > "$ROOT/index.html"
  chmod 644 "$ROOT/index.html"
fi

CODE=""
if command -v curl >/dev/null 2>&1; then
  CODE=$(curl -s --noproxy '*' -o /dev/null -w '%{http_code}' "http://127.0.0.1/$NAME/" || true)
elif wget -q --no-proxy -O /dev/null "http://127.0.0.1/$NAME/"; then
  CODE=200
fi

echo "Файл игры: $ROOT/$NAME/index.html"
if [ "$CODE" = 200 ]; then
  echo "Готово, проверил: nginx отдаёт игру."
  echo "Откройте в браузере: http://<IP сервера>/$NAME/"
else
  echo "Файл на месте, но nginx по адресу /$NAME/ ответил кодом ${CODE:-?}." >&2
  echo "Пришлите в чат вывод команды: nginx -T 2>&1 | grep -E 'listen|root|server_name|include'" >&2
  exit 1
fi
