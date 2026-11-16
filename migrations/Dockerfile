# Helicone migrations (Flyway for Postgres, ch_hcone.py for ClickHouse), official
# image pinned by version and digest, plus a first-admin bootstrap.
FROM helicone/migrations:v2025.08.21@sha256:11f024de19a13b74ad3c8ff904bd34777c8b2286fbe7a54f5c84ec57b4a68946

RUN pip install --no-cache-dir "psycopg[binary]==3.2.10"

COPY migrate.sh bootstrap.py /railway/
RUN chmod 0755 /railway/migrate.sh

CMD ["/railway/migrate.sh"]
