# Testing image for phpMyAdmin
#
# Build against the locally built base image so the test suite exercises the
# exact image under development:
#   docker build --build-arg BASE_IMAGE=phpmyadmin/phpmyadmin:testing \
#     -t phpmyadmin/phpmyadmin:testing-suite testing/
# The default (phpmyadmin/phpmyadmin:latest) keeps docker-compose.testing.yml
# working unchanged.

ARG BASE_IMAGE=phpmyadmin/phpmyadmin:latest
FROM ${BASE_IMAGE}

# Install test dependencies
RUN apk add --no-cache curl py2-pip
COPY requirements.txt /
RUN pip install -r /requirements.txt

COPY test-mariadb.ini test-mysql.ini /etc/supervisor.d/
COPY phpmyadmin_test.py test-docker.sh validate_world_sql.py world.sql /