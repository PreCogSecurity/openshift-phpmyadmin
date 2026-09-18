DOCKER_REPO = phpmyadmin/phpmyadmin
TEST_IMAGE = phpmyadmin/phpmyadmin:testing-suite
COMPOSE_TEST = docker-compose.test.yml

.PHONY: all build build_nc run logs clean stop rm prune test test-down test-suite

all: build run logs

build:
	docker build -t ${DOCKER_REPO}:testing .

build_nc:
	docker build --no-cache=true -t ${DOCKER_REPO}:testing .

test-suite:
	docker build --build-arg BASE_IMAGE=${DOCKER_REPO}:testing -t ${TEST_IMAGE} testing/

test: build test-suite
	./testing/run-e2e.sh

test-down:
	docker-compose -f ${COMPOSE_TEST} down

run:
	docker-compose -f docker-compose.testing.yml up -d

logs:
	docker-compose -f docker-compose.testing.yml logs

clean: stop rm prune

stop:
	docker-compose -f docker-compose.testing.yml stop

rm:
	docker-compose -f docker-compose.testing.yml rm

prune:
	docker rm `docker ps -q -a --filter status=exited`
	docker rmi `docker images -q --filter "dangling=true"`
