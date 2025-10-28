# Atlas Trading — Oracle PL/SQL + Flask Demo

A compact, production-style demo that showcases **Oracle SQL/PLSQL** design, a clean **Flask** UI, and the practices a System Analyst role values: **packages, triggers, views**, **audit logs**, **least-privilege access**, and **traceable test flows**.


---

## ✨ Highlights

- **Oracle schema**: SECURITY, PORTFOLIO, COUNTERPARTY, TRADE, POSITION, AUDIT_LOG (+ view `VW_PORTFOLIO_PNL`)
- **Business logic in PL/SQL**: `PKG_TRADING.add_trade`, `replace_trade`, `cancel_trade`, `get_position`
- **Data governance**: audit on every state change; referential integrity; no implicit cascades
- **Flask UI**: Trades, Add Trade, Position, Positions Summary, Audit Log
- **Deploy locally with Docker**: Oracle Free 23c (ARM-friendly for Apple M-chips)

---

## 🧭 Screenshots

`docs/screenshots/`

1. **Trades** — list with badges, cancel action  
2. **Add Trade** — validated form, dropdowns  
3. **Position** — net qty + avg cost (calls `get_position`)  
4. **Positions Summary** — portfolio-level cost view  
5. **Audit Log** — who/what/when trail

---

## 🏗
