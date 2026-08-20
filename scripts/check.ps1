$ErrorActionPreference = 'Stop'

docker compose exec -T postgres sh -c 'psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f /workspace/tests/sql/00_smoke_test.sql'
docker compose exec -T postgres sh -c 'psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "SELECT current_database() AS database_name, version();"'

Write-Output 'Database Master checks passed.'
