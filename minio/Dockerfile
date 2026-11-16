# S3-compatible storage for request and response bodies. Helicone's compose file
# uses these community builds of MinIO (minio/minio left Docker Hub).
FROM pgsty/mc:RELEASE.2026-09-16T00-00-00Z@sha256:cfc83108c3abb371f8fb84d99c1fdc88f8c237e022409b0081fb7c0a3be634dd AS mc
FROM pgsty/minio:RELEASE.2026-08-04T00-00-00Z@sha256:b6bfe7239bfc83fb90d31612d9704d86039dd714f7904b3f1ad68f211e602372

COPY --from=mc /usr/bin/mc /usr/bin/mc
COPY start.sh /railway/start.sh

ENTRYPOINT ["/bin/sh", "/railway/start.sh"]
