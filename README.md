[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/helicone?utm_medium=integration&utm_source=button&utm_campaign=helicone)

# Helicone on Railway

A Railway template for [Helicone](https://github.com/Helicone/helicone), the open-source LLM observability platform: point your OpenAI or Anthropic client at it and every request is logged with cost, latency, tokens and the full prompt and response.

**Version:** Helicone `v2025.08.21` (the newest published images of `helicone/web`, `helicone/jawn` and `helicone/migrations`), pinned by digest.

## What it deploys

Every service except Postgres builds from this repo, one folder per service:

| Service | Folder | Role | Public | Volume |
|---|---|---|---|---|
| `helicone` | `router/` | Caddy router on the one public domain: `/jawn/*` to Jawn, bucket paths to MinIO, the rest to the dashboard. Closes sign-up. | yes | – |
| `web` | `web/` | Helicone dashboard (Next.js, Better Auth) | no | – |
| `jawn` | `jawn/` | Helicone API and LLM proxy | via router | – |
| `migrations` | `migrations/` | Runs Helicone's Postgres and ClickHouse migrations on each deploy, creates the first admin, then exits | no | – |
| `clickhouse` | `clickhouse/` | ClickHouse 24.3.13.40 (request analytics) | no | `/var/lib/clickhouse` |
| `minio` | `minio/` | S3 storage for request and response bodies (`pgsty/minio`, the build Helicone's compose file uses) | no (presigned links via router) | `/data` |
| `Postgres` | Railway | Accounts, organizations, API keys | no | Railway's |

## Variables

All are set by the template. The only prompt is `HELICONE_ADMIN_EMAIL` on `migrations`.

- `migrations`: `HELICONE_ADMIN_EMAIL` (your login), `HELICONE_ADMIN_PASSWORD` (generated, read it from the service's variables), `CLICKHOUSE_HQL_PASSWORD` (generated), database references.
- `web`, `jawn`: `APP_URL` (`https://` plus the router's public domain), `BETTER_AUTH_SECRET` (generated on `web`, referenced by `jawn`), Postgres, ClickHouse and MinIO references, `PORT`.
- `clickhouse`: `CLICKHOUSE_PASSWORD` (generated). `minio`: `MINIO_ROOT_USER`, `MINIO_ROOT_PASSWORD` (generated).
- `helicone`: `PORT`, `WEB_UPSTREAM`, `JAWN_UPSTREAM`, `S3_UPSTREAM` (private-network references). Set `HELICONE_ALLOW_SIGNUP=true` here while teammates create accounts.

Fixed Helicone settings (on-prem mode, bucket names, Helm chart placeholders) are in each service's `start.sh`.

## First login

1. Deploy, entering your email as `HELICONE_ADMIN_EMAIL`.
2. Wait until `migrations` logs `migrations and bootstrap finished`.
3. Open `https://YOUR-DOMAIN/signin` and sign in with that email and the `HELICONE_ADMIN_PASSWORD` value from the `migrations` variables.
4. Create a Helicone API key in Settings, then send requests through `https://YOUR-DOMAIN/jawn/v1/gateway/oai/v1` (OpenAI) or `https://YOUR-DOMAIN/jawn/v1/gateway/anthropic` with the header `Helicone-Auth: Bearer YOUR-HELICONE-KEY`.

## Updates

Railway tells everyone who deployed this template when a change lands on `main` of this repo, and they choose when to apply it. Each version is listed in [CHANGELOG.md](CHANGELOG.md), breaking changes first. To upgrade Helicone, bump the `FROM` lines of `web/`, `jawn/` and `migrations/` together; the `migrations` service applies new schema changes on its next deploy.

## Local test

`docker compose up --build`, then open `http://localhost:8080` and sign in as `admin@example.com` / `localadminpassword` (local test values only).

## License

The wrapper files in this repo are MIT. Helicone is Apache-2.0, ClickHouse Apache-2.0, MinIO AGPL-3.0, Caddy Apache-2.0.
