# Atlas Investment Demo (Oracle + PL/SQL + Flask)

A small but production-style demo for **trade capture & positions** on **Oracle Database** with:
- **PL/SQL package** (`PKG_TRADING`) for `add_trade`, `cancel_trade`, `replace_trade`, and `get_position`
- Clean **schema** (PK/FK, indexes), **audit log**, and a **positions view**
- Minimal **Flask** UI to create/cancel trades and view positions/audit
- Governance: **least-privilege roles**, audit, and a traceability-first test plan

> Built to mirror a **System Analyst** workflow at KIA: Oracle schema design, PL/SQL packaging, views/indexes, roles/grants, SRS/BPMN, and UAT evidence.

---

## Quick start (Apple-silicon M-series and Intel)

### 1) Start Oracle in Docker (Free 23c)
```bash
docker rm -f oraxe 2>/dev/null || true
docker pull --platform linux/arm64/v8 gvenzl/oracle-free:23-slim   # Apple Silicon
# docker pull gvenzl/oracle-free:23-slim                          # Intel runners/CI

docker run -d --name oraxe \
  --platform $(uname -m | grep -qi arm && echo linux/arm64/v8 || echo linux/amd64) \
  -p 1521:1521 -p 5500:5500 \
  --shm-size=1g \
  -e ORACLE_PASSWORD=Oracle123 \
  -e APP_USER=atlas \
  -e APP_USER_PASSWORD=Atlas123 \
  gvenzl/oracle-free:23-slim
```

Wait for DATABASE IS READY TO USE!.

### 2) Create schema, package, and seed reference rows
```bash
make db-setup
```

### 3) Run the app
```bash
python3 -m venv venv && source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
python app/app.py
```

Open: http://127.0.0.1:5000
