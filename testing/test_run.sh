#!/bin/sh
# Standalone unit tests for run.sh.
#
# Verifies that run.sh generates config.secret.inc.php with a 32-character
# blowfish_secret, that the generation is idempotent, and that the runtime
# directories and log file are created.
#
# Usage: sh testing/test_run.sh
# Requires only a POSIX shell and coreutils; no Docker or network access.

set -u

TEST_ROOT=$(mktemp -d)
trap 'rm -rf "$TEST_ROOT"' EXIT

export PMA_CONFIG_DIR="$TEST_ROOT/config"
export NGINX_CLIENT_BODY_TEMP="$TEST_ROOT/nginx"
export PHP_RUN_DIR="$TEST_ROOT/php-run"
export PHP_FPM_LOG="$TEST_ROOT/php-fpm.log"

mkdir -p "$PMA_CONFIG_DIR"

failures=0
checks=0

# check <description> <command...>
check() {
    DESCRIPTION="$1"
    shift
    checks=$((checks + 1))
    if "$@" ; then
        echo "ok - $DESCRIPTION"
    else
        failures=$((failures + 1))
        echo "not ok - $DESCRIPTION"
    fi
}

# Run run.sh with a non-phpmyadmin argument so it never execs supervisord.
check "run.sh exits successfully without supervisord" sh run.sh not-phpmyadmin

# 1. config.secret.inc.php is generated with a 32-character blowfish_secret.
check "config.secret.inc.php is generated" test -f "$PMA_CONFIG_DIR/config.secret.inc.php"

SECRET=$(grep "blowfish_secret" "$PMA_CONFIG_DIR/config.secret.inc.php" | cut -d"'" -f4)
LENGTH=$(printf '%s' "$SECRET" | wc -c)
check "blowfish_secret is 32 characters (got $LENGTH)" test "$LENGTH" -eq 32

# 2. config.user.inc.php is created.
check "config.user.inc.php is created" test -f "$PMA_CONFIG_DIR/config.user.inc.php"

# 3. Runtime directories and log file are created.
check "nginx client_body_temp directory is created" test -d "$NGINX_CLIENT_BODY_TEMP"
check "php run directory is created" test -d "$PHP_RUN_DIR"
check "php-fpm log file is created" test -f "$PHP_FPM_LOG"

# 4. Idempotency: a second run must not regenerate the secret.
SECRET_BEFORE="$SECRET"
check "run.sh is idempotent (second run exits 0)" sh run.sh not-phpmyadmin

SECRET_AFTER=$(grep "blowfish_secret" "$PMA_CONFIG_DIR/config.secret.inc.php" | cut -d"'" -f4)
check "blowfish_secret is unchanged on second run" test "$SECRET_BEFORE" = "$SECRET_AFTER"

if [ "$failures" -ne 0 ] ; then
    echo "$failures of $checks checks failed"
    exit 1
fi

echo "All $checks checks passed"
exit 0