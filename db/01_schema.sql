-- Core reference data
CREATE TABLE SECURITY (
  security_id    NUMBER PRIMARY KEY,
  symbol         VARCHAR2(20) UNIQUE NOT NULL,
  sec_type       VARCHAR2(20) CHECK (sec_type IN ('EQUITY','BOND','FUND')),
  currency       CHAR(3) NOT NULL
);

CREATE TABLE PORTFOLIO (
  portfolio_id   NUMBER PRIMARY KEY,
  name           VARCHAR2(100) UNIQUE NOT NULL,
  base_currency  CHAR(3) NOT NULL
);

CREATE TABLE COUNTERPARTY (
  counterparty_id NUMBER PRIMARY KEY,
  name            VARCHAR2(100) UNIQUE NOT NULL
);

CREATE TABLE TRADE (
  trade_id        NUMBER PRIMARY KEY,
  portfolio_id    NUMBER NOT NULL REFERENCES PORTFOLIO(portfolio_id),
  security_id     NUMBER NOT NULL REFERENCES SECURITY(security_id),
  counterparty_id NUMBER REFERENCES COUNTERPARTY(counterparty_id),
  side            CHAR(1) CHECK (side IN ('B','S')) NOT NULL,
  qty             NUMBER(18,4) CHECK (qty > 0) NOT NULL,
  price           NUMBER(18,6) CHECK (price >= 0) NOT NULL,
  trade_dt        DATE DEFAULT TRUNC(SYSDATE) NOT NULL,
  status          VARCHAR2(12) DEFAULT 'NEW' CHECK (status IN ('NEW','CANCELLED','REPLACED')),
  created_at      DATE DEFAULT SYSDATE NOT NULL
);

CREATE TABLE POSITION (
  portfolio_id     NUMBER NOT NULL REFERENCES PORTFOLIO(portfolio_id),
  security_id      NUMBER NOT NULL REFERENCES SECURITY(security_id),
  qty_net          NUMBER(18,4) DEFAULT 0 NOT NULL,
  cost_basis_total NUMBER(18,6) DEFAULT 0 NOT NULL,
  avg_cost         NUMBER(18,6) GENERATED ALWAYS AS
                    (CASE WHEN qty_net <> 0 THEN cost_basis_total/qty_net ELSE 0 END) VIRTUAL,
  CONSTRAINT pk_position PRIMARY KEY (portfolio_id, security_id)
);

CREATE TABLE AUDIT_LOG (
  audit_id     NUMBER PRIMARY KEY,
  action_name  VARCHAR2(50) NOT NULL,
  ref_id       NUMBER,
  details      VARCHAR2(4000),
  username     VARCHAR2(128) DEFAULT SYS_CONTEXT('USERENV','SESSION_USER'),
  created_at   DATE DEFAULT SYSDATE
);

-- Sequences (LiveSQL supports these)
CREATE SEQUENCE seq_trade START WITH 1000;
CREATE SEQUENCE seq_audit START WITH 1;

-- Helpful indexes
CREATE INDEX ix_trade_portfolio ON TRADE(portfolio_id);
CREATE INDEX ix_trade_security  ON TRADE(security_id);
CREATE INDEX ix_trade_status_dt ON TRADE(status, trade_dt);
