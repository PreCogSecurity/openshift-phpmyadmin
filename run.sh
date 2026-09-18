#!/bin/sh
# phpMyAdmin container entrypoint.
#
# Every filesystem location can be overridden through environment variables so
# the script can be exercised in a sandbox outside the container; see
# testing/test_run.sh.

PMA_CONFIG_DIR="${PMA_CONFIG_DIR:-/etc/phpmyadmin}"
NGINX_CLIENT_BODY_TEMP="${NGINX_CLIENT_BODY_TEMP:-/var/nginx/client_body_temp}"
PHP_RUN_DIR="${PHP_RUN_DIR:-/var/run/php}"
PHP_FPM_LOG="${PHP_FPM_LOG:-/var/log/php-fpm.log}"

if [ ! -f "$PMA_CONFIG_DIR/config.secret.inc.php" ] ; then
    cat > "$PMA_CONFIG_DIR/config.secret.inc.php" <<EOT
<?php
\$cfg['blowfish_secret'] = '$(tr -dc 'a-zA-Z0-9~!@#$%^&*_()+}{?></";.,[]=-' < /dev/urandom | fold -w 32 | head -n 1)';
EOT
fi

if [ ! -f "$PMA_CONFIG_DIR/config.user.inc.php" ] ; then
  touch "$PMA_CONFIG_DIR/config.user.inc.php"
fi

mkdir -p "$NGINX_CLIENT_BODY_TEMP"
mkdir -p "$PHP_RUN_DIR"
touch "$PHP_FPM_LOG"

if [ "$1" = 'phpmyadmin' ]; then
    exec supervisord --nodaemon --configuration="/etc/supervisord.conf" --loglevel=info
fi