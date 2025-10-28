CREATE OR REPLACE VIEW VW_PORTFOLIO_PNL AS
SELECT  p.portfolio_id,
        s.symbol,
        pos.qty_net,
        pos.avg_cost,
        (pos.qty_net * pos.avg_cost) AS cost_total
FROM POSITION pos
JOIN SECURITY s  ON s.security_id  = pos.security_id
JOIN PORTFOLIO p ON p.portfolio_id = pos.portfolio_id;

SELECT * FROM VW_PORTFOLIO_PNL ORDER BY portfolio_id, symbol;
