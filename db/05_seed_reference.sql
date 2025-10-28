MERGE INTO portfolio d
USING (SELECT 10 id,'Atlas Core' name,'KWD' bc FROM dual) s
ON (d.portfolio_id=s.id)
WHEN MATCHED THEN UPDATE SET d.name=s.name, d.base_currency=s.bc
WHEN NOT MATCHED THEN INSERT (portfolio_id,name,base_currency) VALUES (s.id,s.name,s.bc);

MERGE INTO portfolio d
USING (SELECT 11 id,'Atlas Income' name,'KWD' bc FROM dual) s
ON (d.portfolio_id=s.id)
WHEN MATCHED THEN UPDATE SET d.name=s.name, d.base_currency=s.bc
WHEN NOT MATCHED THEN INSERT (portfolio_id,name,base_currency) VALUES (s.id,s.name,s.bc);

MERGE INTO portfolio d
USING (SELECT 12 id,'Atlas Growth' name,'KWD' bc FROM dual) s
ON (d.portfolio_id=s.id)
WHEN MATCHED THEN UPDATE SET d.name=s.name, d.base_currency=s.bc
WHEN NOT MATCHED THEN INSERT (portfolio_id,name,base_currency) VALUES (s.id,s.name,s.bc);

MERGE INTO security d
USING (SELECT 1 id,'ATLS' sym,'EQUITY' typ,'KWD' curr FROM dual) s
ON (d.security_id=s.id)
WHEN MATCHED THEN UPDATE SET d.symbol=s.sym, d.sec_type=s.typ, d.currency=s.curr
WHEN NOT MATCHED THEN INSERT (security_id,symbol,sec_type,currency) VALUES (s.id,s.sym,s.typ,s.curr);

MERGE INTO security d
USING (SELECT 2 id,'KFIN' sym,'EQUITY' typ,'KWD' curr FROM dual) s
ON (d.security_id=s.id)
WHEN MATCHED THEN UPDATE SET d.symbol=s.sym, d.sec_type=s.typ, d.currency=s.curr
WHEN NOT MATCHED THEN INSERT (security_id,symbol,sec_type,currency) VALUES (s.id,s.sym,s.typ,s.curr);

MERGE INTO security d
USING (SELECT 3 id,'OQ8' sym,'EQUITY' typ,'KWD' curr FROM dual) s
ON (d.security_id=s.id)
WHEN MATCHED THEN UPDATE SET d.symbol=s.sym, d.sec_type=s.typ, d.currency=s.curr
WHEN NOT MATCHED THEN INSERT (security_id,symbol,sec_type,currency) VALUES (s.id,s.sym,s.typ,s.curr);

MERGE INTO security d
USING (SELECT 4 id,'NBK' sym,'EQUITY' typ,'KWD' curr FROM dual) s
ON (d.security_id=s.id)
WHEN MATCHED THEN UPDATE SET d.symbol=s.sym, d.sec_type=s.typ, d.currency=s.curr
WHEN NOT MATCHED THEN INSERT (security_id,symbol,sec_type,currency) VALUES (s.id,s.sym,s.typ,s.curr);

MERGE INTO security d
USING (SELECT 5 id,'KIAF' sym,'FUND' typ,'KWD' curr FROM dual) s
ON (d.security_id=s.id)
WHEN MATCHED THEN UPDATE SET d.symbol=s.sym, d.sec_type=s.typ, d.currency=s.curr
WHEN NOT MATCHED THEN INSERT (security_id,symbol,sec_type,currency) VALUES (s.id,s.sym,s.typ,s.curr);

MERGE INTO counterparty d
USING (SELECT 100 id,'Atlas Broker' name FROM dual) s
ON (d.counterparty_id=s.id)
WHEN MATCHED THEN UPDATE SET d.name=s.name
WHEN NOT MATCHED THEN INSERT (counterparty_id,name) VALUES (s.id,s.name);

MERGE INTO counterparty d
USING (SELECT 101 id,'Gulf Securities' name FROM dual) s
ON (d.counterparty_id=s.id)
WHEN MATCHED THEN UPDATE SET d.name=s.name
WHEN NOT MATCHED THEN INSERT (counterparty_id,name) VALUES (s.id,s.name);

MERGE INTO counterparty d
USING (SELECT 102 id,'Kuwait Markets' name FROM dual) s
ON (d.counterparty_id=s.id)
WHEN MATCHED THEN UPDATE SET d.name=s.name
WHEN NOT MATCHED THEN INSERT (counterparty_id,name) VALUES (s.id,s.name);

COMMIT;
