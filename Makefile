# Schemaverse developer entry points. Everything runs in Docker.
COMPOSE := docker compose -f docker/compose.yml

.PHONY: up down reset logs psql player smoke build test

docker/.env:
	@cp docker/.env.example docker/.env && echo "created docker/.env from example; edit SCHEMAVERSE_PASSWORD"

build: docker/.env
	$(COMPOSE) build

up: docker/.env            ## build images, deploy schema, start the ticker
	$(COMPOSE) up -d --build

down:                      ## stop containers, keep data
	$(COMPOSE) down

reset:                     ## stop containers and delete the database volume
	$(COMPOSE) down -v

logs:                      ## follow the ticker
	$(COMPOSE) logs -f tic

psql:                      ## psql as the schemaverse owner
	$(COMPOSE) exec db psql -U schemaverse -d schemaverse

player:                    ## make player NAME=alice PASS=secret
	./scripts/new_player.sh "$(NAME)" "$(PASS)"

smoke: docker/.env         ## fresh stack, two players, ten tics, assertions
	./scripts/smoke.sh

test: docker/.env             ## run the pgTAP suite against the running stack
	./scripts/test.sh
