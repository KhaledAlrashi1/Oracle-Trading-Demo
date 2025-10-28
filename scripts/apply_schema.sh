#!/usr/bin/env bash
set -euo pipefail
./scripts/run_sql.sh sql/01_schema.sql
./scripts/run_sql.sh sql/02_pkg_trading.sql
./scripts/run_sql.sh sql/03_seed_reference.sql
