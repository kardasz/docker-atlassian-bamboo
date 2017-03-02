# which service (from docker-compose.yml:services) to run commands agains
SERVICE ?=

BIND_IP ?= 127.0.0.1
TZ ?= UTC
BAMBOO_BACKUP_VOLUME ?=
POSTGRES_PASSWORD ?= bamboo
PROJECT_NAME ?= atlassian_bamboo

EXEC_ARGS ?=
UP_ARGS ?= -d --force-recreate
DOWN_ARGS ?= --remove-orphans
BUILD_ARGS ?=

COMPOSE_ENV = BIND_IP=$(BIND_IP) TZ=$(TZ) BAMBOO_BACKUP_VOLUME=${BAMBOO_BACKUP_VOLUME} POSTGRES_PASSWORD=$(POSTGRES_PASSWORD)
COMPOSE_FILE_ARGS ?= -f $(CURDIR)/docker-compose.yml

ifeq ($(shell uname -s),Darwin)
XARGS_OPTS =
else
XARGS_OPTS = -r
endif

build:
	$(COMPOSE_ENV) docker-compose $(COMPOSE_FILE_ARGS) -p $(PROJECT_NAME) build --no-cache

push: build
	$(COMPOSE_ENV) docker-compose $(COMPOSE_FILE_ARGS) -p $(PROJECT_NAME) push bamboo

up: env-check
	$(COMPOSE_ENV) docker-compose $(COMPOSE_FILE_ARGS) -p $(PROJECT_NAME) up $(UP_ARGS) ${SERVICE}

logs: env-check
	$(COMPOSE_ENV) docker-compose $(COMPOSE_FILE_ARGS) -p $(PROJECT_NAME) logs --tail=100 -f

stop: env-check
	$(COMPOSE_ENV) docker-compose $(COMPOSE_FILE_ARGS) -p $(PROJECT_NAME) stop ${SERVICE}

rm: stop
	$(COMPOSE_ENV) docker-compose $(COMPOSE_FILE_ARGS) -p $(PROJECT_NAME) rm -f ${SERVICE}

restart: env-check
	$(COMPOSE_ENV) docker-compose $(COMPOSE_FILE_ARGS) -p $(PROJECT_NAME) restart $(SERVICE)

down: env-check
	$(COMPOSE_ENV) docker-compose $(COMPOSE_FILE_ARGS) -p $(PROJECT_NAME) down $(DOWN_ARGS)

exec: up
	$(COMPOSE_ENV) docker-compose $(COMPOSE_FILE_ARGS) -p $(PROJECT_NAME) exec -T $(SERVICE) $(EXEC_ARGS)

bash: up
	$(COMPOSE_ENV) docker-compose $(COMPOSE_FILE_ARGS) -p $(PROJECT_NAME) exec $(SERVICE) bash

bamboo: up
	$(COMPOSE_ENV) docker-compose $(COMPOSE_FILE_ARGS) -p $(PROJECT_NAME) exec bamboo bash

psql: up
	$(COMPOSE_ENV) docker-compose $(COMPOSE_FILE_ARGS) -p $(PROJECT_NAME) exec $(SERVICE) psql -U bamboo

ps:
	$(COMPOSE_ENV) docker-compose $(COMPOSE_FILE_ARGS) -p $(PROJECT_NAME) ps

env-check:
ifeq ($(shell uname -s),Darwin)
	ifconfig lo0 | grep -qF '$(BIND_IP)' || sudo ifconfig lo0 alias $(BIND_IP)
endif

.PHONY: %
.DEFAULT: run