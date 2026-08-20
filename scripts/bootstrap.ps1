$ErrorActionPreference = 'Stop'

docker compose up -d --wait
docker compose exec -T postgres sh -c 'psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f /workspace/sql/bootstrap/99_bootstrap.sql'
docker compose exec -T postgres sh -c 'psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f /workspace/tests/sql/00_smoke_test.sql'

Write-Output 'Database Master bootstrap completed.'
