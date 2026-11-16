#!/bin/sh
# Start MinIO on PORT (default 9000), then create Helicone's buckets once it answers.
set -e
: "${MINIO_ROOT_USER:?MINIO_ROOT_USER must be set}"
: "${MINIO_ROOT_PASSWORD:?MINIO_ROOT_PASSWORD must be set}"
PORT="${PORT:-9000}"
BUCKETS="${S3_BUCKETS:-request-response-storage prompt-body-storage hql-store}"
export MINIO_BROWSER="${MINIO_BROWSER:-off}"

minio server /data --address ":$PORT" &
pid=$!
trap 'kill -TERM $pid 2>/dev/null' TERM INT

i=0
until mc alias set local "http://127.0.0.1:$PORT" "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD" >/dev/null 2>&1; do
  i=$((i + 1)); [ "$i" -le 60 ] || { echo "railway: MinIO did not start" >&2; exit 1; }
  sleep 1
done
for b in $BUCKETS; do mc mb --ignore-existing "local/$b"; done
echo "railway: buckets ready: $BUCKETS"

wait $pid
