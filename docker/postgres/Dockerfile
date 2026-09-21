# Schemaverse database image.
# Bleeding edge on purpose: PostgreSQL 19 beta by default, 18 as the CI safety net.
# Override with:  docker compose build --build-arg PG_IMAGE=postgres:18
ARG PG_IMAGE=postgres:19beta3
FROM ${PG_IMAGE}

# The official image already carries the PGDG apt repo for its own major version,
# so extensions come from packages. pgtap is for the test suite, pg_cron is for
# round control once Phase 2 lands.
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      "postgresql-${PG_MAJOR}-pgtap" \
      "postgresql-${PG_MAJOR}-cron" \
 && rm -rf /var/lib/apt/lists/*

COPY initdb/ /docker-entrypoint-initdb.d/
