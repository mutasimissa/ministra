#!/bin/bash
set -e

DEPLOY_DIR="/home/ministra/ministra/www/stalker_portal/deploy"
MARKER_FILE="/data/storage/.phing_initialized"

wait_for_mysql() {
  echo "Waiting for MySQL to be ready..."
  until php -r "
    try {
      new PDO(
        'mysql:host=${MINISTRA_MYSQL_HOST};port=${MINISTRA_MYSQL_PORT};dbname=${MINISTRA_MYSQL_DBNAME}',
        '${MINISTRA_MYSQL_USER}',
        '${MINISTRA_MYSQL_PASS}'
      );
      exit(0);
    } catch (Exception \$e) {
      exit(1);
    }
  " 2>/dev/null; do
    echo "MySQL not ready yet, retrying in 3s..."
    sleep 3
  done
  echo "MySQL is ready."
}

run_phing() {
  if [ ! -f "$MARKER_FILE" ]; then
    echo "Running phing deploy..."
    cd "$DEPLOY_DIR"
    phing
    touch "$MARKER_FILE"
    echo "Phing deploy complete."
  else
    echo "Phing already ran previously, skipping."
  fi
}

patch_custom_ini() {
  local ini="/home/ministra/ministra/www/stalker_portal/server/custom.ini"
  if [ -f "$ini" ]; then
    echo "Patching custom.ini with environment credentials..."
    local tmp="/tmp/custom.ini.tmp"
    sed \
      -e "s|^mysql_host = .*|mysql_host = ${MINISTRA_MYSQL_HOST}|" \
      -e "s|^mysql_port = .*|mysql_port = ${MINISTRA_MYSQL_PORT}|" \
      -e "s|^mysql_user = .*|mysql_user = ${MINISTRA_MYSQL_USER}|" \
      -e "s|^mysql_pass = .*|mysql_pass = ${MINISTRA_MYSQL_PASS}|" \
      -e "s|^db_name = .*|db_name = ${MINISTRA_MYSQL_DBNAME}|" \
      -e "s|^memcache_host = .*|memcache_host = ${MINISTRA_MEMCACHE_HOST}|" \
      "$ini" > "$tmp"
    cp "$tmp" "$ini"
    rm "$tmp"
    echo "custom.ini patched."
  fi
}

set_admin_credentials() {
  echo "Setting admin credentials..."
  php -r "
    \$pdo = new PDO(
      'mysql:host=${MINISTRA_MYSQL_HOST};port=${MINISTRA_MYSQL_PORT};dbname=${MINISTRA_MYSQL_DBNAME}',
      '${MINISTRA_MYSQL_USER}',
      '${MINISTRA_MYSQL_PASS}'
    );
    \$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    \$hash = md5('${MINISTRA_ADMIN_PASSWORD}');
    \$stmt = \$pdo->prepare('UPDATE administrators SET login = ?, pass = ? WHERE login = \"admin\" OR id = 1');
    \$stmt->execute(['${MINISTRA_ADMIN_USER}', \$hash]);
    echo \"Admin credentials updated.\n\";
  "
}

patch_custom_ini
wait_for_mysql
run_phing
set_admin_credentials

exec /docker-entrypoint.sh /usr/sbin/apache2ctl -D FOREGROUND
