# ClickHouse for Helicone's request analytics, the version Helicone's compose file pins.
FROM clickhouse/clickhouse-server:24.3.13.40@sha256:363ae7df18768bcf16fd528e048f762e2d5fd13059f6757eeac6a0cb7b1eacba

# Let the default user manage users (Helicone's migrations create a read-only hql_user).
ENV CLICKHOUSE_DEFAULT_ACCESS_MANAGEMENT=1

# Listen on IPv6 and IPv4, so Railway's private network reaches it.
COPY listen.xml /etc/clickhouse-server/config.d/zz-railway-listen.xml
# Small-instance memory settings.
COPY low-memory.xml /etc/clickhouse-server/config.d/zz-railway-low-memory.xml
