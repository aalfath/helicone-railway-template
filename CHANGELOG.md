# Changelog

## 2026-11-16: Helicone v2025.08.21

First version.

- Helicone `web`, `jawn` and `migrations` `v2025.08.21`, pinned by digest.
- ClickHouse `24.3.13.40`, MinIO (`pgsty/minio`) `RELEASE.2026-08-04T00-00-00Z`, Caddy `2.11.9`, Railway Postgres.
- ClickHouse runs with fixed, small thread pools and `max_threads=4`, so it stays under Railway's per-container thread limit on many-CPU hosts.
- `migrations` waits for Postgres and ClickHouse with 5-second connect timeouts, so a redeploy can't hang on a database that is restarting.
- One public domain through the `helicone` router; first admin created by `migrations`; public sign-up closed.
