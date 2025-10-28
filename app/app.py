import os
from typing import List, Tuple, Optional

from flask import Flask, render_template, request, redirect, url_for, flash
from dotenv import load_dotenv
import oracledb

load_dotenv()
app = Flask(__name__)
app.secret_key = "dev"  # change for production

def get_conn():
    return oracledb.connect(
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD"),
        dsn=os.getenv("DB_DSN"),
    )

# ---------- Tiny DB helpers ----------
def fetchall(sql: str, params: Tuple = ()) -> list:
    with get_conn() as conn:
        cur = conn.cursor()
        cur.execute(sql, params)
        return cur.fetchall()

def fetchone(sql: str, params: Tuple = ()) -> Optional[Tuple]:
    rows = fetchall(sql, params)
    return rows[0] if rows else None

def exec_sql(sql: str, params: Tuple = ()) -> None:
    with get_conn() as conn:
        cur = conn.cursor()
        cur.execute(sql, params)
        conn.commit()

def exec_proc(name: str, params: List):
    with get_conn() as conn:
        cur = conn.cursor()
        cur.callproc(name, params)
        conn.commit()

# ---------- Catalog lists ----------
def list_portfolios():
    return fetchall("SELECT portfolio_id, name, base_currency FROM portfolio ORDER BY portfolio_id")

def list_securities():
    return fetchall("SELECT security_id, symbol, sec_type, currency FROM security ORDER BY security_id")

def list_counterparties():
    return fetchall("SELECT counterparty_id, name FROM counterparty ORDER BY counterparty_id")

# ---------- ROUTES ----------
@app.route("/")
def home():
    return redirect(url_for("trades"))

@app.route("/trades")
def trades():
    rows = fetchall("""
        SELECT t.trade_id, p.name, s.symbol, t.side, t.qty, t.price, t.status, TO_CHAR(t.trade_dt,'YYYY-MM-DD')
        FROM trade t
        JOIN portfolio p ON p.portfolio_id = t.portfolio_id
        JOIN security  s ON s.security_id  = t.security_id
        ORDER BY t.trade_id DESC
    """)
    return render_template("trades.html", rows=rows)

@app.route("/add-trade", methods=["GET","POST"])
def add_trade():
    if request.method == "POST":
        try:
            portfolio_id = int(request.form["portfolio_id"])
            security_id  = int(request.form["security_id"])
            side         = request.form["side"].upper()
            qty          = float(request.form["qty"])
            price        = float(request.form["price"])
            counterparty = request.form.get("counterparty_id")
            counterparty = int(counterparty) if counterparty else None

            # server-side validation
            if side not in ("B","S"): raise ValueError("Side must be B or S.")
            if qty <= 0:              raise ValueError("Quantity must be > 0.")
            if price < 0:             raise ValueError("Price must be >= 0.")

            with get_conn() as conn:
                cur = conn.cursor()
                o_id = cur.var(oracledb.NUMBER)
                cur.callproc("pkg_trading.add_trade",
                             [portfolio_id, security_id, side, qty, price, counterparty, None, o_id])
                conn.commit()
                flash(f"Trade added (ID {int(o_id.getvalue())})", "success")
        except Exception as e:
            flash(f"{e}", "error")
        return redirect(url_for("trades"))

    return render_template(
        "add_trade.html",
        portfolios=list_portfolios(), securities=[(r[0], r[1]) for r in list_securities()],
        cps=list_counterparties()
    )

@app.route("/cancel/<int:trade_id>", methods=["POST"])
def cancel(trade_id):
    try:
        exec_proc("pkg_trading.cancel_trade", [trade_id])
        flash(f"Trade {trade_id} cancelled", "success")
    except Exception as e:
        flash(f"{e}", "error")
    return redirect(url_for("trades"))

# -------- Edit Trade (qty/price via replace_trade) --------
@app.route("/edit-trade/<int:trade_id>", methods=["GET","POST"])
def edit_trade(trade_id):
    # Fetch current trade
    t = fetchone("""
        SELECT trade_id, portfolio_id, security_id, side, qty, price, status, TO_CHAR(trade_dt,'YYYY-MM-DD HH24:MI:SS')
        FROM trade WHERE trade_id = :1
    """, (trade_id,))
    if not t:
        flash("Trade not found.", "error")
        return redirect(url_for("trades"))

    if request.method == "POST":
        try:
            # We allow editing quantity and price only (side/portfolio/security changes usually require cancel/new)
            new_qty   = float(request.form["qty"])
            new_price = float(request.form["price"])
            if new_qty <= 0:      raise ValueError("Quantity must be > 0.")
            if new_price < 0:     raise ValueError("Price must be >= 0.")
            if t[6] != "NEW":     raise ValueError("Only NEW trades can be edited/replaced.")

            with get_conn() as conn:
                cur = conn.cursor()
                o_new = cur.var(oracledb.NUMBER)
                # pkg_trading.replace_trade(p_trade_id, p_new_qty, p_new_price, o_new_trade_id)
                cur.callproc("pkg_trading.replace_trade", [trade_id, new_qty, new_price, o_new])
                conn.commit()
                flash(f"Trade {trade_id} replaced by {int(o_new.getvalue())}.", "success")
        except Exception as e:
            flash(f"{e}", "error")
        return redirect(url_for("trades"))

    return render_template("edit_trade.html", t=t)

# -------- Position & Summary --------
@app.route("/position")
def position():
    portfolios = list_portfolios()
    securities = list_securities()
    pid = request.args.get("portfolio_id", type=int) or (portfolios[0][0] if portfolios else None)
    sid = request.args.get("security_id", type=int)  or (securities[0][0] if securities else None)
    qty = avg = None
    if pid and sid:
        with get_conn() as conn:
            cur = conn.cursor()
            o_qty = cur.var(oracledb.NUMBER)
            o_avg = cur.var(oracledb.NUMBER)
            cur.callproc("pkg_trading.get_position", [pid, sid, o_qty, o_avg])
            qty = float(o_qty.getvalue() or 0)
            avg = float(o_avg.getvalue() or 0)
    return render_template("position.html",
                           portfolios=[(p[0], p[1]) for p in portfolios],
                           securities=[(s[0], s[1]) for s in securities],
                           pid=pid, sid=sid, qty=qty, avg=avg)

@app.route("/positions-summary")
def positions_summary():
    with get_conn() as conn:
        cur = conn.cursor()
        cur.execute("""
            CREATE OR REPLACE VIEW VW_PORTFOLIO_PNL AS
            SELECT  p.portfolio_id,
                    p.name AS portfolio_name,
                    s.symbol,
                    pos.qty_net,
                    pos.avg_cost,
                    (pos.qty_net * pos.avg_cost) AS cost_total
            FROM POSITION pos
            JOIN SECURITY s  ON s.security_id  = pos.security_id
            JOIN PORTFOLIO p ON p.portfolio_id = pos.portfolio_id
        """)
        conn.commit()
    rows = fetchall("""
        SELECT portfolio_name, symbol, qty_net, avg_cost, cost_total
        FROM VW_PORTFOLIO_PNL
        ORDER BY portfolio_name, symbol
    """)
    return render_template("positions_summary.html", rows=rows)

@app.route("/audit")
def audit():
    rows = fetchall("""
        SELECT audit_id, action_name, ref_id, username, TO_CHAR(created_at,'YYYY-MM-DD HH24:MI:SS')
        FROM audit_log ORDER BY audit_id DESC
    """)
    return render_template("audit.html", rows=rows)

# -------- Catalog (simple CRUD) --------
@app.route("/catalog", methods=["GET","POST"])
def catalog():
    # Handle creates
    if request.method == "POST":
        try:
            kind = request.form["kind"]
            if kind == "portfolio":
                name = request.form["name"].strip()
                base = request.form.get("base_currency","KWD").strip() or "KWD"
                exec_sql("""
                    INSERT INTO portfolio (portfolio_id, name, base_currency)
                    SELECT NVL(MAX(portfolio_id),0)+1, :1, :2 FROM portfolio
                """, (name, base))
                flash("Portfolio added.", "success")
            elif kind == "security":
                symbol = request.form["symbol"].strip().upper()
                sec_type = request.form.get("sec_type","EQUITY").strip().upper()
                currency = request.form.get("currency","KWD").strip().upper()
                exec_sql("""
                    INSERT INTO security (security_id, symbol, sec_type, currency)
                    SELECT NVL(MAX(security_id),0)+1, :1, :2, :3 FROM security
                """, (symbol, sec_type, currency))
                flash("Security added.", "success")
            elif kind == "counterparty":
                name = request.form["name"].strip()
                exec_sql("""
                    INSERT INTO counterparty (counterparty_id, name)
                    SELECT NVL(MAX(counterparty_id),0)+1, :1 FROM counterparty
                """, (name,))
                flash("Counterparty added.", "success")
        except oracledb.Error as e:
            flash(f"DB error: {e}", "error")
        return redirect(url_for("catalog"))

    return render_template(
        "catalog.html",
        portfolios=list_portfolios(),
        securities=list_securities(),
        counterparties=list_counterparties()
    )

@app.post("/catalog/delete/<kind>/<int:item_id>")
def catalog_delete(kind, item_id):
    try:
        if kind == "portfolio":
            exec_sql("DELETE FROM portfolio WHERE portfolio_id = :1", (item_id,))
        elif kind == "security":
            exec_sql("DELETE FROM security WHERE security_id = :1", (item_id,))
        elif kind == "counterparty":
            exec_sql("DELETE FROM counterparty WHERE counterparty_id = :1", (item_id,))
        else:
            raise ValueError("Unknown catalog type.")
        flash("Deleted.", "success")
    except oracledb.Error as e:
        # Will fail if referenced by trades/positions → FK keeps us safe
        flash(f"DB error: {e}", "error")
    return redirect(url_for("catalog"))

if __name__ == "__main__":
    app.run(debug=True)
