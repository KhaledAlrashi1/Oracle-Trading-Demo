# Oracle Trading Demo (Flask + PL/SQL)

---

## 🎯 Objectives

- **Data model clarity**: Clean tables for portfolios, securities, counterparties, trades, positions, and an audit trail.
- **PL/SQL package API**: Business logic centralized in `PKG_TRADING` (Add / Replace / Cancel / Get Position).
- **Reporting view**: `VW_PORTFOLIO_PNL` for a quick portfolio positions summary.
- **Governance**: Constraints, referential integrity, least-privilege runtime user, and auditable changes.
- **Usable UI**: A simple Flask front end to capture trades and visualize positions.

---

## 🧩 What this demonstrates (at a glance)

- **Oracle & PL/SQL**: package, views, indexes, constraints.
- **Process thinking**: clear CRUD + replace/cancel flows backed by the package.
- **Controls**: audit log for every mutation.
- **System analysis**: separation of UI vs. database logic, minimal & readable code.

---

## 🚀 Quick Start (local)

> Assumes Docker is installed and you’re on Apple silicon (M1/M2).  
> Service name used: `FREEPDB1`.

```bash
# 1) Start Oracle Free 23c (ARM64)
docker run -d --name oraxe \
  --platform linux/arm64/v8 \
  -p 1521:1521 -p 5500:5500 \
  --shm-size=1g \
  -e ORACLE_PASSWORD=Oracle123 \
  -e APP_USER=atlas \
  -e APP_USER_PASSWORD=Atlas123 \
  gvenzl/oracle-free:23-slim

# 2) Python setup
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env   # then set DB_USER/PASSWORD/DSN if needed

# 3) Create schema + package
docker cp sql/01_schema.sql      oraxe:/tmp/01_schema.sql
docker cp sql/02_pkg_trading.sql oraxe:/tmp/02_pkg_trading.sql
docker exec -it oraxe sqlplus -L atlas/Atlas123@localhost:1521/FREEPDB1 @/tmp/01_schema.sql
docker exec -it oraxe sqlplus -L atlas/Atlas123@localhost:1521/FREEPDB1 @/tmp/02_pkg_trading.sql

# 4) Run the app
python app.py
# Open http://127.0.0.1:5000
