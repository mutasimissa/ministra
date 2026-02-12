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

install_npm
wait_for_mysql
run_phing

exec /docker-entrypoint.sh /usr/sbin/apache2ctl -D FOREGROUND
