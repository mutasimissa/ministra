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

install_npm() {
  if ! npm --version 2>/dev/null | grep -q "2.15.11"; then
    echo "Installing npm 2.15.11..."
    npm install -g npm@2.15.11
    echo "npm 2.15.11 installed."
  else
    echo "npm 2.15.11 already installed, skipping."
  fi
}

patch_custom_ini() {
  local ini="/home/ministra/ministra/www/stalker_portal/server/custom.ini"
  if [ -f "$ini" ]; then
    echo "Patching custom.ini with environment credentials..."
    sed -i "s|^mysql_host = .*|mysql_host = ${MINISTRA_MYSQL_HOST}|" "$ini"
    sed -i "s|^mysql_port = .*|mysql_port = ${MINISTRA_MYSQL_PORT}|" "$ini"
    sed -i "s|^mysql_user = .*|mysql_user = ${MINISTRA_MYSQL_USER}|" "$ini"
    sed -i "s|^mysql_pass = .*|mysql_pass = ${MINISTRA_MYSQL_PASS}|" "$ini"
    sed -i "s|^db_name = .*|db_name = ${MINISTRA_MYSQL_DBNAME}|" "$ini"
    sed -i "s|^memcache_host = .*|memcache_host = ${MINISTRA_MEMCACHE_HOST}|" "$ini"
    echo "custom.ini patched."
  fi
}

install_npm
patch_custom_ini
wait_for_mysql
run_phing

exec /docker-entrypoint.sh /usr/sbin/apache2ctl -D FOREGROUND
