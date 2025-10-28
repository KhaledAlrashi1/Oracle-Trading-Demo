-- SPEC
CREATE OR REPLACE PACKAGE pkg_trading AS
  PROCEDURE add_trade(
    p_portfolio_id     IN NUMBER,
    p_security_id      IN NUMBER,
    p_side             IN CHAR,      -- 'B' or 'S'
    p_qty              IN NUMBER,
    p_price            IN NUMBER,
    p_counterparty_id  IN NUMBER DEFAULT NULL,
    p_trade_dt         IN DATE   DEFAULT TRUNC(SYSDATE),
    o_trade_id         OUT NUMBER
  );

  PROCEDURE cancel_trade(p_trade_id IN NUMBER);

  PROCEDURE replace_trade(
    p_trade_id      IN NUMBER,
    p_new_qty       IN NUMBER,
    p_new_price     IN NUMBER,
    o_new_trade_id  OUT NUMBER
  );

  PROCEDURE get_position(
    p_portfolio_id IN NUMBER,
    p_security_id  IN NUMBER,
    o_qty_net      OUT NUMBER,
    o_avg_cost     OUT NUMBER
  );
END pkg_trading;
/
-- BODY
CREATE OR REPLACE PACKAGE BODY pkg_trading AS

  PROCEDURE log_audit(p_action VARCHAR2, p_ref NUMBER, p_details VARCHAR2) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    INSERT INTO AUDIT_LOG(audit_id, action_name, ref_id, details)
    VALUES (seq_audit.NEXTVAL, p_action, p_ref, p_details);
    COMMIT;
  END;

  PROCEDURE post_position(p_portfolio_id NUMBER, p_security_id NUMBER,
                          p_side CHAR, p_qty NUMBER, p_price NUMBER) IS
  BEGIN
    IF p_side = 'B' THEN
      MERGE INTO POSITION d
      USING (SELECT p_portfolio_id pid, p_security_id sid FROM dual) s
      ON (d.portfolio_id = s.pid AND d.security_id = s.sid)
      WHEN MATCHED THEN UPDATE SET
        d.qty_net = d.qty_net + p_qty,
        d.cost_basis_total = d.cost_basis_total + (p_qty * p_price)
      WHEN NOT MATCHED THEN
        INSERT (portfolio_id, security_id, qty_net, cost_basis_total)
        VALUES (p_portfolio_id, p_security_id, p_qty, p_qty * p_price);
    ELSE
      DECLARE v_qty NUMBER; v_cost NUMBER; v_avg NUMBER;
      BEGIN
        SELECT qty_net, cost_basis_total,
               CASE WHEN qty_net <> 0 THEN cost_basis_total/qty_net ELSE 0 END
        INTO v_qty, v_cost, v_avg
        FROM POSITION
        WHERE portfolio_id = p_portfolio_id AND security_id = p_security_id
        FOR UPDATE;

        IF v_qty < p_qty THEN
          RAISE_APPLICATION_ERROR(-20001,'Cannot sell more than current position.');
        END IF;

        UPDATE POSITION
        SET qty_net = v_qty - p_qty,
            cost_basis_total = v_cost - (v_avg * p_qty)
        WHERE portfolio_id = p_portfolio_id AND security_id = p_security_id;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          RAISE_APPLICATION_ERROR(-20002,'Cannot sell: no existing position.');
      END;
    END IF;
  END;

  PROCEDURE add_trade(
    p_portfolio_id IN NUMBER, p_security_id IN NUMBER, p_side IN CHAR,
    p_qty IN NUMBER, p_price IN NUMBER, p_counterparty_id IN NUMBER,
    p_trade_dt IN DATE, o_trade_id OUT NUMBER) IS
  BEGIN
    IF p_qty <= 0 OR p_price < 0 THEN
      RAISE_APPLICATION_ERROR(-20003,'Invalid qty/price.');
    END IF;
    IF p_side NOT IN ('B','S') THEN
      RAISE_APPLICATION_ERROR(-20004,'Side must be B or S.');
    END IF;

    INSERT INTO TRADE(trade_id, portfolio_id, security_id, counterparty_id,
                      side, qty, price, trade_dt, status)
    VALUES (seq_trade.NEXTVAL, p_portfolio_id, p_security_id, p_counterparty_id,
            p_side, p_qty, p_price, NVL(p_trade_dt, TRUNC(SYSDATE)), 'NEW')
    RETURNING trade_id INTO o_trade_id;

    post_position(p_portfolio_id, p_security_id, p_side, p_qty, p_price);
    log_audit('ADD_TRADE', o_trade_id,
              'Added '||p_side||' '||p_qty||' @'||p_price);
  END;

  PROCEDURE cancel_trade(p_trade_id IN NUMBER) IS
    r TRADE%ROWTYPE;
  BEGIN
    SELECT * INTO r FROM TRADE WHERE trade_id = p_trade_id FOR UPDATE;
    IF r.status <> 'NEW' THEN RETURN; END IF;

    UPDATE TRADE SET status = 'CANCELLED' WHERE trade_id = p_trade_id;

    post_position(r.portfolio_id, r.security_id,
                  CASE WHEN r.side='B' THEN 'S' ELSE 'B' END,
                  r.qty, r.price);

    log_audit('CANCEL_TRADE', p_trade_id, 'Cancelled and reversed');
  END;

  PROCEDURE replace_trade(p_trade_id IN NUMBER, p_new_qty IN NUMBER,
                          p_new_price IN NUMBER, o_new_trade_id OUT NUMBER) IS
    r TRADE%ROWTYPE;
  BEGIN
    SELECT * INTO r FROM TRADE WHERE trade_id = p_trade_id;
    cancel_trade(p_trade_id);
    UPDATE TRADE SET status='REPLACED' WHERE trade_id = p_trade_id;

    add_trade(r.portfolio_id, r.security_id, r.side,
              p_new_qty, p_new_price, r.counterparty_id,
              TRUNC(SYSDATE), o_new_trade_id);
    log_audit('REPLACE_TRADE', p_trade_id, 'Replaced with '||o_new_trade_id);
  END;

  PROCEDURE get_position(p_portfolio_id IN NUMBER, p_security_id IN NUMBER,
                         o_qty_net OUT NUMBER, o_avg_cost OUT NUMBER) IS
  BEGIN
    SELECT qty_net, avg_cost INTO o_qty_net, o_avg_cost
    FROM POSITION
    WHERE portfolio_id = p_portfolio_id AND security_id = p_security_id;
  EXCEPTION WHEN NO_DATA_FOUND THEN
    o_qty_net := 0; o_avg_cost := 0;
  END;

END pkg_trading;
/
