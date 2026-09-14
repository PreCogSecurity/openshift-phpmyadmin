#!/bin/sh

NAME="$1"

if [ -n "$2" ] ; then
    PORT="$2"
fi

if [ -n "$3" ] ; then
    SERVER="$3"
    PMA_HOST=$3
else
    SERVER=''
fi

# Set PHPMyAdmin environment
PHPMYADMIN_HOSTNAME=${TESTSUITE_HOSTNAME:=localhost}
PHPMYADMIN_URL=http://$PHPMYADMIN_HOSTNAME:$PORT/

# Color text output
GREEN="\033[0;32m"
RED="\033[0;31m"
NC="\033[0m" # No Color

ret=0
# Check if script is running inside container
if [ -f /.dockerenv ] ; then
    echo "Tests running inside container..."

    # Set database environment
    PHPMYADMIN_DB_HOSTNAME=${PMA_HOST:=localhost}
    PHPMYADMIN_DB_PORT=${PMA_PORT:=3306}
    PHPMYADMIN_DB_URL=http://$PHPMYADMIN_DB_HOSTNAME:$PHPMYADMIN_DB_PORT/

    # Wait for database to start
    TIMEOUT=0
    while ! curl "$PHPMYADMIN_DB_URL" >/dev/null 2>&1; do
        echo "Waiting for ${PHPMYADMIN_DB_HOSTNAME} database start..."
        sleep 10
        TIMEOUT=$((TIMEOUT + 1))
        if [ $TIMEOUT -gt 3 ] ; then
            echo "Failed to connect ${PHPMYADMIN_DB_HOSTNAME} database!"
            echo "Result of ${PHPMYADMIN_DB_HOSTNAME} tests: ${RED}FAILED${NC}"
            ret=1
            exit 1
        fi
    done
else
    echo "Tests running outside container..."
    docker ps -a
    COMMAND_HOST="docker exec ${NAME}"
fi

# Run a command inside the phpMyAdmin container when running outside it, or
# directly on the host when running inside the container.
container_cmd() {
    if [ -n "$COMMAND_HOST" ] ; then
        # shellcheck disable=SC2086 # COMMAND_HOST is intentionally word-split
        $COMMAND_HOST "$@"
    else
        "$@"
    fi
}

# Wait for container to start
TIMEOUT=0
while ! container_cmd ps aux | grep -q nginx ; do
    echo "Waiting for PHPMyAdmin start..."
    sleep 1
    TIMEOUT=$((TIMEOUT + 1))
    if [ $TIMEOUT -gt 10 ] ; then
        echo "Failed to connect PHPMyAdmin!"
        echo "Result of ${PHPMYADMIN_DB_HOSTNAME} tests: ${RED}FAILED${NC}"
        ret=1
        exit 1
    fi
done

# Validate the SQL fixture before importing it
if [ -f ./validate_world_sql.py ] ; then
    VALIDATE=./validate_world_sql.py
else
    VALIDATE=./testing/validate_world_sql.py
fi
python "$VALIDATE"
ret=$?
if [ $ret -ne 0 ] ; then
    echo "Result of ${PHPMYADMIN_DB_HOSTNAME} tests: ${RED}FAILED${NC}"
    exit $ret
fi

# Perform tests
if [ $ret -eq 0 ] ; then
    if [ -f ./phpmyadmin_test.py ] ; then
        FILENAME=./phpmyadmin_test.py
    else
        FILENAME=./testing/phpmyadmin_test.py
    fi
    if [ -n "$SERVER" ] ; then
        python "$FILENAME" --url "$PHPMYADMIN_URL" --username root --password "$TESTSUITE_PASSWORD" --server "$SERVER"
    else
        python "$FILENAME" --url "$PHPMYADMIN_URL" --username root --password "$TESTSUITE_PASSWORD"
    fi
    ret=$?
fi

# Show debug output in case of failure
if [ $ret -ne 0 ] ; then
    curl "$PHPMYADMIN_URL"
    container_cmd ps faux
    container_cmd cat /var/log/php-fpm.log
    container_cmd cat /var/log/nginx-error.log
    container_cmd cat /var/log/supervisord.log
    echo "Result of ${PHPMYADMIN_DB_HOSTNAME} tests: ${RED}FAILED${NC}"
    exit $ret
fi

echo "Result of ${PHPMYADMIN_DB_HOSTNAME} tests: ${GREEN}SUCCESS${NC}"