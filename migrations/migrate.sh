#!/bin/bash
# Runs on every deploy of the migrations service, then exits:
#   1. wait for Postgres and ClickHouse,
#   2. Helicone's own migrations (idempotent),
#   3. bootstrap.py: hql_user password and the first admin account (idempotent).
set -euo pipefail
: "${DATABASE_URL:?DATABASE_URL must be set}"
: "${CLICKHOUSE_HOST:?CLICKHOUSE_HOST must be set}"
export CLICKHOUSE_USER="${CLICKHOUSE_USER:-default}"

# Flyway settings from DATABASE_URL.
eval "$(python3 - <<'PY'
import os, shlex, urllib.parse as u
p = u.urlparse(os.environ["DATABASE_URL"])
port = p.port or 5432
db = p.path.lstrip("/")
print("export FLYWAY_URL=" + shlex.quote(
    f"jdbc:postgresql://{p.hostname}:{port}/{db}?sslmode=disable&options=-c%20search_path%3Dpublic,extensions"))
print("export FLYWAY_USER=" + shlex.quote(u.unquote(p.username or "postgres")))
print("export FLYWAY_PASSWORD=" + shlex.quote(u.unquote(p.password or "")))
print(f"PG_HOST={shlex.quote(p.hostname)} PG_PORT={port}")
PY
)"

# Host and port for the wait loop.
eval "$(python3 - <<'PY'
import os, shlex, urllib.parse as u
p = u.urlparse(os.environ["CLICKHOUSE_HOST"])
print(f"CH_HOST={shlex.quote(p.hostname)} CH_PORT={p.port or 8123}")
PY
)"

wait_tcp() {
  local name="$1" host="$2" port="$3" i=0
  until (exec 3<>"/dev/tcp/$host/$port") 2>/dev/null; do
    i=$((i + 1)); [ "$i" -le 180 ] || { echo "railway: $name not reachable at $host:$port" >&2; exit 1; }
    echo "railway: waiting for $name ($host:$port)"; sleep 5
  done
}
wait_tcp Postgres "$PG_HOST" "$PG_PORT"
wait_tcp ClickHouse "$CH_HOST" "$CH_PORT"
until curl -fsS "http://$CH_HOST:$CH_PORT/ping" >/dev/null 2>&1; do
  echo "railway: waiting for ClickHouse /ping"; sleep 5
done

cd /app
echo "railway: Postgres migrations"
flyway repair -configFiles=/app/supabase/flyway.conf
flyway migrate -configFiles=/app/supabase/flyway.conf

echo "railway: ClickHouse migrations"
# ch_hcone.py reads CLICKHOUSE_HOST, CLICKHOUSE_USER and CLICKHOUSE_PASSWORD from the
# environment. It prints its arguments, so the password is never passed as a flag.
if [ -n "${CLICKHOUSE_PASSWORD:-}" ]; then
  python3 /app/clickhouse/ch_hcone.py --upgrade --skip-confirmation
else
  python3 /app/clickhouse/ch_hcone.py --upgrade --no-password --skip-confirmation
fi

python3 /railway/bootstrap.py
echo "railway: migrations and bootstrap finished"
