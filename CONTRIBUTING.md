# Contributing to openshift-phpmyadmin

Thanks for your interest in contributing! This repository packages phpMyAdmin
for Docker and OpenShift. Please keep the following guidelines in mind.

## Reporting issues

This repository contains only the Docker/OpenShift integration of phpMyAdmin.
Please do not report bugs in phpMyAdmin itself here — use
<https://github.com/phpmyadmin/phpmyadmin/issues> instead.

## Building the image locally

```bash
docker build -t phpmyadmin/phpmyadmin:testing .
```

## Running the tests

The test suite is split into two layers:

1. Unit tests that need no Docker or network access:

   ```bash
   php testing/test_config.php            # config.inc.php environment parsing
   sh testing/test_run.sh                 # run.sh secret generation and idempotency
   python testing/validate_world_sql.py   # world.sql fixture shape
   ```

2. End-to-end test that needs Docker and docker-compose only:

   ```bash
   make test
   ```

   `make test` builds the image, starts a MariaDB server and phpMyAdmin via
   `docker-compose.test.yml`, runs `testing/phpmyadmin_test.py` against them,
   and tears the stack down afterwards.

## Submitting changes

- Keep each feature or fix in its own small commit that includes the tests
  pinning the new behaviour.
- Run the unit tests and `make test` before opening a pull request.
- Follow the existing style of the repository (POSIX `sh`, PHP 5/7 compatible
  syntax, no new dependencies unless required).