#!/usr/bin/env bash
set -euo pipefail
docker exec -i oraxe sqlplus -s -L atlas/Atlas123@localhost:1521/FREEPDB1 @"$1"

