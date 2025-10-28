#!/usr/bin/env bash
set -euo pipefail
docker rm -f oraxe 2>/dev/null || true
docker pull --platform linux/arm64/v8 gvenzl/oracle-free:23-slim
docker run -d --name oraxe \
  --platform linux/arm64/v8 \
  -p 1521:1521 -p 5500:5500 \
  --shm-size=1g \
  -e ORACLE_PASSWORD=Oracle123 \
  -e APP_USER=atlas \
  -e APP_USER_PASSWORD=Atlas123 \
  gvenzl/oracle-free:23-slim
echo "Waiting for DB to initialize..."
sleep 10
docker logs -f oraxe
