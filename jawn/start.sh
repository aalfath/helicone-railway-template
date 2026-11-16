#!/bin/sh
# Derive Jawn's settings from APP_URL and the database references, set the fixed
# self-hosting defaults from Helicone's Helm chart, then run Jawn without the
# optional prompt-security sidecar.
set -e
: "${APP_URL:?APP_URL must be set to the public URL, e.g. https://YOUR-DOMAIN}"
: "${DATABASE_URL:?DATABASE_URL must be set}"
APP_URL="${APP_URL%/}"

export PORT="${PORT:-8585}"
export NEXT_PUBLIC_APP_URL="$APP_URL"
export APP_URL
export BETTER_AUTH_URL="$APP_URL"
export BETTER_AUTH_TRUSTED_ORIGINS="$APP_URL"
export S3_ENDPOINT_PUBLIC="${S3_ENDPOINT_PUBLIC:-$APP_URL}"
export SUPABASE_DATABASE_URL="${SUPABASE_DATABASE_URL:-$DATABASE_URL}"

# DB_* parts for code paths that read them instead of the URL.
eval "$(node -e '
const u = new URL(process.env.DATABASE_URL);
const q = (s) => "\x27" + String(s).replace(/\x27/g, "\x27\\\x27\x27") + "\x27";
console.log("export DB_HOST=" + q(u.hostname));
console.log("export DB_PORT=" + q(u.port || "5432"));
console.log("export DB_NAME=" + q(u.pathname.slice(1)));
console.log("export DB_USER=" + q(decodeURIComponent(u.username)));
console.log("export DB_PASSWORD=" + q(decodeURIComponent(u.password)));
')"

export NEXT_PUBLIC_BETTER_AUTH=true
export IS_HELICONE_CLOUD=false
export ENV="${ENV:-development}"
export VERCEL_ENV="${VERCEL_ENV:-development}"
export ENABLE_CRON_JOB="${ENABLE_CRON_JOB:-true}"
export ENABLE_PROMPT_SECURITY="${ENABLE_PROMPT_SECURITY:-false}"
export CLICKHOUSE_USER="${CLICKHOUSE_USER:-default}"
export CLICKHOUSE_HQL_USER="${CLICKHOUSE_HQL_USER:-hql_user}"
export S3_BUCKET_NAME="${S3_BUCKET_NAME:-request-response-storage}"
export S3_PROMPT_BUCKET_NAME="${S3_PROMPT_BUCKET_NAME:-prompt-body-storage}"
export HQL_STORE_BUCKET="${HQL_STORE_BUCKET:-hql-store}"
export S3_FORCE_PATH_STYLE="${S3_FORCE_PATH_STYLE:-true}"
# Dev-mode key sync target (Cloudflare worker in Helicone cloud); unused here.
export HELICONE_WORKER_API="${HELICONE_WORKER_API:-http://localhost:$PORT}"
export HELICONE_WORKER_URL="${HELICONE_WORKER_URL:-http://localhost:$PORT/v1/gateway/oai}"
export OPENAI_API_KEY="${OPENAI_API_KEY:-sk-}"
export STRIPE_SECRET_KEY="${STRIPE_SECRET_KEY:-sk_test_not_used_self_hosted}"
export AZURE_API_KEY="${AZURE_API_KEY:-anything}"
export AZURE_API_VERSION="${AZURE_API_VERSION:-anything}"
export AZURE_BASE_URL="${AZURE_BASE_URL:-anything}"
export AZURE_DEPLOYMENT_NAME="${AZURE_DEPLOYMENT_NAME:-anything}"

cd /usr/src/app/valhalla/jawn
exec node dist/valhalla/jawn/src/index.js
