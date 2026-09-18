#!/bin/sh
# Wait for the phpMyAdmin container started by docker-compose.test.yml to
# accept HTTP connections before running the E2E test.
#
# Usage: testing/wait-for-e2e.sh [port] [timeout_seconds]

PORT="${1:-8091}"
TIMEOUT="${2:-60}"
URL="http://localhost:${PORT}/"

GREEN="\033[0;32m"
RED="\033[0;31m"
NC="\033[0m" # No Color

i=0
while [ "$i" -lt "$TIMEOUT" ] ; do
    if curl -s -o /dev/null "$URL" ; then
        echo "${GREEN}phpMyAdmin is up at ${URL}${NC}"
        exit 0
    fi
    sleep 1
    i=$((i + 1))
done

echo "${RED}Timed out waiting for phpMyAdmin at ${URL}${NC}"
docker-compose -f docker-compose.test.yml logs phpmyadmin
exit 1