.PHONY: compose_build up test_db create_database clean down bundle tests lint backend-unit-tests frontend-unit-tests test build watch start redis-cli bash

compose_build:
	COMPOSE_DOCKER_CLI_BUILD=1 DOCKER_BUILDKIT=1 docker-compose build

up:
	COMPOSE_DOCKER_CLI_BUILD=1 DOCKER_BUILDKIT=1 docker-compose up -d

test_db:
	@for i in `seq 1 5`; do \
		if (docker-compose exec postgres sh -c 'psql -U postgres -c "select 1;"' 2>&1 > /dev/null) then break; \
		else echo "postgres initializing..."; sleep 5; fi \
	done
	docker-compose exec postgres sh -c 'psql -U postgres -c "drop database if exists tests;" && psql -U postgres -c "create database tests;"'

create_database:
	docker-compose run server create_db

clean:
	docker-compose down && docker-compose rm

down:
	docker-compose down

bundle:
	docker-compose run server bin/bundle-extensions

tests:
	docker-compose run server tests

lint:
	./bin/flake8_tests.sh

backend-unit-tests: up test_db
	docker-compose run --rm --name tests server tests

frontend-unit-tests: bundle
	CYPRESS_INSTALL_BINARY=0 PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=1 yarn --frozen-lockfile
	yarn bundle
	yarn test

test: lint backend-unit-tests frontend-unit-tests

build: bundle
	yarn build

watch: bundle
	yarn watch

start: bundle
	yarn start

redis-cli:
	docker-compose run --rm redis redis-cli -h redis

bash:
	docker-compose run --rm server bash

docker-build:
	docker build --tag redash:latest . --build-arg skip_frontend_build="true"

bundle-extensions:
	docker-compose exec server /app/ext-lib/docker-entrypoint bundle_extensions

frontend-clean:
	docker-compose run frontend yarn clean

frontend-build:
	docker-compose run frontend yarn install 
	docker-compose run frontend yarn build

frontend-restart:
	docker-compose stop frontend
	docker-compose up -d 

server-restart:
	docker-compose stop server
	docker-compose up -d

all-restart:
	docker-compose stop server
	docker-compose stop worker
	docker-compose stop scheduler
	docker-compose up -d

build_up: compose_build up