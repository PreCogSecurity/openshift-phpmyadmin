#!/bin/sh
# Run the phpMyAdmin E2E test suite in isolation.
#
# Brings up a MariaDB server and the locally built phpMyAdmin image via
# docker-compose.test.yml, waits for phpMyAdmin to accept connections, runs
# the E2E test from the testing-suite image, then tears the stack down.
#
# Usage: make test   (or: testing/run-e2e.sh)
# Requires Docker and docker-compose only.

set -e

COMPOSE_FILE="docker-compose.test.yml"

docker-compose -f "$COMPOSE_FILE" up -d db phpmyadmin
trap 'docker-compose -f "$COMPOSE_FILE" down' EXIT

./testing/wait-for-e2e.sh

docker-compose -f "$COMPOSE_FILE" run --rm test