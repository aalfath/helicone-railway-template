#!/bin/sh
# Derive Helicone's URL settings from APP_URL (the public router domain) and set
# the fixed self-hosting defaults from Helicone's Helm chart.
set -e
: "${APP_URL:?APP_URL must be set to the public URL, e.g. https://YOUR-DOMAIN}"
APP_URL="${APP_URL%/}"

export PORT="${PORT:-3000}"
export HOSTNAME="${HOSTNAME_BIND:-::}"
export NEXT_PUBLIC_APP_URL="$APP_URL"
export SITE_URL="$APP_URL"
export BETTER_AUTH_URL="$APP_URL"
export BETTER_AUTH_TRUSTED_ORIGINS="$APP_URL"
export NEXT_PUBLIC_HELICONE_JAWN_SERVICE="$APP_URL/jawn"
export NEXT_PUBLIC_API_BASE_PATH="$APP_URL/jawn"
export NEXT_PUBLIC_BASE_PATH="$APP_URL/jawn/v1/gateway/oai/v1"
export SUPABASE_DATABASE_URL="${SUPABASE_DATABASE_URL:-$DATABASE_URL}"

export NEXT_PUBLIC_BETTER_AUTH=true
export NEXT_PUBLIC_IS_ON_PREM=true
export ENV="${ENV:-development}"
export VERCEL_ENV="${VERCEL_ENV:-development}"
export CLICKHOUSE_USER="${CLICKHOUSE_USER:-default}"
export S3_BUCKET_NAME="${S3_BUCKET_NAME:-request-response-storage}"
export S3_FORCE_PATH_STYLE="${S3_FORCE_PATH_STYLE:-true}"
export ENABLE_PROMPT_SECURITY="${ENABLE_PROMPT_SECURITY:-false}"
export OPENAI_API_KEY="${OPENAI_API_KEY:-sk-}"
export STRIPE_SECRET_KEY="${STRIPE_SECRET_KEY:-sk_test_not_used_self_hosted}"
export AZURE_API_KEY="${AZURE_API_KEY:-anything}"
export AZURE_API_VERSION="${AZURE_API_VERSION:-anything}"
export AZURE_BASE_URL="${AZURE_BASE_URL:-anything}"
export AZURE_DEPLOYMENT_NAME="${AZURE_DEPLOYMENT_NAME:-anything}"
export SMTP_PORT="${SMTP_PORT:-587}"
export SMTP_SECURE="${SMTP_SECURE:-false}"

cd /app
exec yarn --cwd web start -p "$PORT" -H "$HOSTNAME"
