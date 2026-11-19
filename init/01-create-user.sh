#!/bin/bash
set -euo pipefail

: "${POSTGRES_USER:?POSTGRES_USER is required}"
: "${POSTGRES_DB:?POSTGRES_DB is required}"
: "${MIGRATION_PASSWORD:?MIGRATION_PASSWORD is required}"
: "${DEVELOPER_PASSWORD:?DEVELOPER_PASSWORD is required}"

require_secret() {
  local name="$1"
  local value="$2"
  if [ "${#value}" -lt 16 ]; then
    echo "${name} precisa ter pelo menos 16 caracteres." >&2
    exit 1
  fi
}

require_secret MIGRATION_PASSWORD "$MIGRATION_PASSWORD"
require_secret DEVELOPER_PASSWORD "$DEVELOPER_PASSWORD"

psql -v ON_ERROR_STOP=1 \
  --username "$POSTGRES_USER" \
  --dbname "$POSTGRES_DB" \
  -v migration_password="$MIGRATION_PASSWORD" \
  -v developer_password="$DEVELOPER_PASSWORD" \
  -v db_name="$POSTGRES_DB" <<-'EOSQL'
    CREATE ROLE migration WITH LOGIN PASSWORD :'migration_password';
    CREATE ROLE developer WITH LOGIN PASSWORD :'developer_password';

    REVOKE ALL ON DATABASE :"db_name" FROM PUBLIC;
    GRANT CONNECT, TEMPORARY ON DATABASE :"db_name" TO migration, developer;
    GRANT CREATE ON DATABASE :"db_name" TO migration;

    REVOKE CREATE ON SCHEMA public FROM PUBLIC;
    ALTER SCHEMA public OWNER TO migration;
    GRANT USAGE ON SCHEMA public TO developer;

    ALTER ROLE migration SET search_path = public;
    ALTER ROLE developer SET search_path = public;

    ALTER DEFAULT PRIVILEGES FOR ROLE migration IN SCHEMA public
      GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO developer;

    ALTER DEFAULT PRIVILEGES FOR ROLE migration IN SCHEMA public
      GRANT USAGE, SELECT ON SEQUENCES TO developer;

    ALTER DEFAULT PRIVILEGES FOR ROLE migration IN SCHEMA public
      GRANT EXECUTE ON FUNCTIONS TO developer;
EOSQL

echo "Papéis migration e developer criados no banco ${POSTGRES_DB}."