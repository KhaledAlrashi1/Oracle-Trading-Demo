-- Enable DBMS_OUTPUT in LiveSQL (instead of SET SERVEROUTPUT)
BEGIN DBMS_OUTPUT.ENABLE; END;
/

-- === Seed (use MERGE so you can re-run safely) ===
MERGE INTO SECURITY d
USING (SELECT 1 security_id, 'ATLS' symbol, 'EQUITY' sec_type, 'KWD' currency FROM dual) s
ON (d.security_id = s.security_id)
WHEN MATCHED THEN UPDATE SET d.symbol=s.symbol, d.sec_type=s.sec_type, d.currency=s.currency
WHEN NOT MATCHED THEN INSERT (security_id, symbol, sec_type, currency)
VALUES (s.security_id, s.symbol, s.sec_type, s.currency);

MERGE INTO SECURITY d
USING (SELECT 2 security_id, 'GULF-FUND' symbol, 'FUND' sec_type, 'KWD' currency FROM dual) s
ON (d.security_id = s.security_id)
WHEN MATCHED THEN UPDATE SET d.symbol=s.symbol, d.sec_type=s.sec_type, d.currency=s.currency
WHEN NOT MATCHED THEN INSERT (security_id, symbol, sec_type, currency)
VALUES (s.security_id, s.symbol, s.sec_type, s.currency);

MERGE INTO PORTFOLIO d
USING (SELECT 10 portfolio_id, 'Atlas Core' name, 'KWD' base_currency FROM dual) s
ON (d.portfolio_id = s.portfolio_id)
WHEN MATCHED THEN UPDATE SET d.name=s.name, d.base_currency=s.base_currency
WHEN NOT MATCHED THEN INSERT (portfolio_id, name, base_currency)
VALUES (s.portfolio_id, s.name, s.base_currency);

MERGE INTO COUNTERPARTY d
USING (SELECT 100 counterparty_id, 'Atlas Broker' name FROM dual) s
ON (d.counterparty_id = s.counterparty_id)
WHEN MATCHED THEN UPDATE SET d.name=s.name
WHEN NOT MATCHED THEN INSERT (counterparty_id, name)
VALUES (s.counterparty_id, s.name);

COMMIT;

-- Sanity check: parents MUST exist
SELECT 'SECURITY='||COUNT(*) AS chk_security FROM SECURITY WHERE security_id IN (1,2);
SELECT 'PORTFOLIO='||COUNT(*) AS chk_portfolio FROM PORTFOLIO WHERE portfolio_id=10;
SELECT 'COUNTERPARTY='||COUNT(*) AS chk_counterparty FROM COUNTERPARTY WHERE counterparty_id=100;

-- === Demo scenario ===
DECLARE
  v_id NUMBER; vq NUMBER; va NUMBER;
BEGIN
  pkg_trading.add_trade(10,1,'B',100,1.250,100,DATE '2025-01-01', v_id);
  pkg_trading.add_trade(10,1,'B', 50,1.300,100,DATE '2025-01-02', v_id);
  pkg_trading.add_trade(10,1,'S', 60,1.400,100,DATE '2025-01-03', v_id);

  pkg_trading.get_position(10,1,vq,va);
  DBMS_OUTPUT.PUT_LINE('Position -> qty='||vq||', avg_cost='||va);
END;
/

-- Inspect
SELECT * FROM POSITION WHERE portfolio_id=10 AND security_id=1;
SELECT trade_id, side, qty, price, status FROM TRADE ORDER BY trade_id;
SELECT audit_id, action_name, ref_id, created_at FROM AUDIT_LOG ORDER BY audit_id;
