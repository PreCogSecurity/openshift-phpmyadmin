# Official phpMyAdmin Docker image

Run phpMyAdmin with Alpine, supervisor, nginx and PHP FPM.

[![Build Status](https://travis-ci.org/phpmyadmin/docker.svg?branch=master)](https://travis-ci.org/phpmyadmin/docker)
[![Docker Pulls](https://img.shields.io/docker/pulls/phpmyadmin/phpmyadmin.svg)][hub]
[![Docker Stars](https://img.shields.io/docker/stars/phpmyadmin/phpmyadmin.svg)][hub]
[![Docker Layers](https://images.microbadger.com/badges/image/phpmyadmin/phpmyadmin.svg)](https://microbadger.com/images/phpmyadmin/phpmyadmin "Get your own image badge on microbadger.com")
[![Docker Version](https://images.microbadger.com/badges/version/phpmyadmin/phpmyadmin.svg)](https://microbadger.com/images/phpmyadmin/phpmyadmin "Get your own version badge on microbadger.com")


All following examples will bring you phpMyAdmin on `http://localhost:8080`
where you can enjoy your happy MySQL administration.

## Credentials

phpMyAdmin does use MySQL server credential, please check the corresponding
server image for information how it is setup.

The official MySQL and MariaDB use following environment variables to define these:

* `MYSQL_ROOT_PASSWORD` - This variable is mandatory and specifies the password that will be set for the `root` superuser account.
* `MYSQL_USER`, `MYSQL_PASSWORD` - These variables are optional, used in conjunction to create a new user and to set that user's password.

## Docker hub tags

You can use following tags on Docker hub:

* `latest` - latest stable release
* `4.6` - latest stable release from the 4.6 branch
* `4.7` - latest stable release from the 4.7 branch
* `edge` - bleeding edge docker image (contains stable phpMyAdmin, but the Docker image changes might not yet be fully tested)
* `edge-4.7` - bleeding edge docker image + latest snapshots from 4.7 branch
* `edge-4.8` - bleeding edge docker image + latest snapshots from 4.8 branch (currently master)

## Usage with linked server

First you need to run MySQL or MariaDB server in Docker, and this image need
link a running mysql instance container:

```
docker run --name myadmin -d --link mysql_db_server:db -p 8080:80 phpmyadmin/phpmyadmin
```

## Usage with external server

You can specify MySQL host in the `PMA_HOST` environment variable. You can also
use `PMA_PORT` to specify port of the server in case it's not the default one:

```
docker run --name myadmin -d -e PMA_HOST=dbhost -p 8080:80 phpmyadmin/phpmyadmin
```

## Usage with arbitrary server

You can use arbitrary servers by adding ENV variable `PMA_ARBITRARY=1` to the startup command:

```
docker run --name myadmin -d -e PMA_ARBITRARY=1 -p 8080:80 phpmyadmin/phpmyadmin
```

## Usage with docker-compose and arbitrary server

This will run phpMyAdmin with arbitrary server - allowing you to specify MySQL/MariaDB
server on login page.

Using the docker-compose.yml from https://github.com/phpmyadmin/docker

```
docker-compose up -d
```

## Run the E2E tests with docker-compose

You can run the E2E tests with the local test environment by running MariaDB/MySQL databases. Adding ENV variable `PHPMYADMIN_RUN_TEST=true` already added on docker-compose file. Simply run:

Using the docker-compose.testing.yml from https://github.com/phpmyadmin/docker

```
docker-compose -f docker-compose.testing.yml up phpmyadmin
```

## Adding Custom Configuration

You can add your own custom config.inc.php settings (such as Configuration Storage setup)
by creating a file named "config.user.inc.php" with the various user defined settings
in it, and then linking it into the container using:

```
-v /some/local/directory/config.user.inc.php:/etc/phpmyadmin/config.user.inc.php
```
On the "docker run" line like this:
```
docker run --name myadmin -d --link mysql_db_server:db -p 8080:80 -v /some/local/directory/config.user.inc.php:/etc/phpmyadmin/config.user.inc.php phpmyadmin/phpmyadmin
```

See the following links for config file information.
https://docs.phpmyadmin.net/en/latest/config.html#config
https://docs.phpmyadmin.net/en/latest/setup.html

## Usage behind reverse proxys

Set the variable ``PMA_ABSOLUTE_URI`` to the fully-qualified path (``https://pma.example.net/``) where the reverse proxy makes phpMyAdmin available.

## Environment variables summary

* ``PMA_ARBITRARY`` - when set to 1 connection to the arbitrary server will be allowed
* ``PMA_HOST`` - define address/host name of the MySQL server
* ``PMA_VERBOSE`` - define verbose name of the MySQL server
* ``PMA_PORT`` - define port of the MySQL server
* ``PMA_HOSTS`` - define comma separated list of address/host names of the MySQL servers
* ``PMA_VERBOSES`` - define comma separated list of verbose names of the MySQL servers
* ``PMA_PORTS`` -  define comma separated list of ports of the MySQL servers
* ``PMA_USER`` and ``PMA_PASSWORD`` - define username to use for config authentication method
* ``PMA_ABSOLUTE_URI`` - define user-facing URI

For more detailed documentation see https://docs.phpmyadmin.net/en/latest/setup.html#installing-using-docker

[hub]: https://hub.docker.com/r/phpmyadmin/phpmyadmin/

Please report any issues with the Docker container to https://github.com/phpmyadmin/docker/issues

# openshift-phpmyadmin-mysql

OpenShift phpMyAdmin MySQL

## Docker registry mirrors

1. http://hub-mirror.c.163.com

## Step1: Upload to OpenShift Docker Registry

1. minishift start
2. minishift docker-env
3. eval $(minishift oc-env)
4. oc login -u developer
5. oc expose service docker-registry -n default 
6. docker login -u developer -p $(oc whoami -t) $(minishift openshift registry) // docker login -u developer -p $(oc whoami -t) 172.30.1.1:5000
7. docker pull phpmyadmin/phpmyadmin:latest
8. docker tag phpmyadmin:latest $(minishift openshift registry)/<project>/phpmyadmin:latest // docker tag phpmyadmin:latest 172.30.1.1:5000/<project>/phpmyadmin:latest
9. docker push $(minishift openshift registry)/<project>/phpmyadmin:latest // docker push 172.30.1.1:5000/<project>/phpmyadmin:latest

## Uninstall

1. minishift oc-env
2. eval $(minishift oc-env)

```bash
oc delete all -l app=<NAME>-phpmyadmin
oc delete all -l app=<NAME>-mysql
oc delete pvc -l app=<NAME>-mysql
oc delete secret -l app=<NAME>-mysql
```

## Run Docker Image As Root

```bash
oc edit scc restricted
```

runAsUser.Type to RunAsAny.

Ensure allowPrivilegedContainer is set to false.

## Troubleshooting

1. Connect to OpenShift docker registry refused.

```bash
docker pull openshift/origin-docker-registry:v3.6.1

oc status -v

oc deploy docker-registry --retry

oc logs -f dc/docker-registry

oc describe svc/docker-registry
```
