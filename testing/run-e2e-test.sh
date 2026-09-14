#!/bin/sh
# Run the E2E test against the phpMyAdmin service of docker-compose.test.yml.
#
# Runs inside the testing-suite container. Retries while the database is
# still starting up.
#
# Usage: testing/run-e2e-test.sh [url] [username] [password]

URL="${1:-http://phpmyadmin/}"
USERNAME="${2:-root}"
PASSWORD="${3:-test123}"

python /testing/validate_world_sql.py || exit 1

ATTEMPTS=10
i=0
while [ "$i" -lt "$ATTEMPTS" ] ; do
    if python /testing/phpmyadmin_test.py --url "$URL" --username "$USERNAME" --password "$PASSWORD" ; then
        exit 0
    fi
    i=$((i + 1))
    echo "E2E test attempt $i failed; retrying in 5s..."
    sleep 5
done

echo "E2E test failed after $ATTEMPTS attempts"
exit 1