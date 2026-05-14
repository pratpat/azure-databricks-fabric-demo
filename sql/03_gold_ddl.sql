-- =====================================================================
-- Gold layer: curated analytics tables and views for BI / Fabric.
-- =====================================================================

-- Daily desk P&L (net cash flow proxy from trades)
CREATE OR REPLACE TABLE capmkt.gold.desk_pnl_daily AS
SELECT  CAST(t.trade_ts AS DATE) AS trade_date,
        tr.desk,
        tr.region,
        SUM(CASE WHEN t.side = 'BUY' THEN -t.notional ELSE t.notional END) AS net_cash_flow,
        COUNT(*)                                                           AS trade_count,
        SUM(t.notional)                                                    AS gross_notional
FROM    capmkt.silver.trades  t
JOIN    capmkt.silver.traders tr USING (trader_id)
GROUP BY CAST(t.trade_ts AS DATE), tr.desk, tr.region;

-- AUM exposure by sector / country
CREATE OR REPLACE TABLE capmkt.gold.exposure_by_sector AS
SELECT  p.as_of_date,
        s.sector,
        s.country,
        SUM(p.market_value_usd)   AS market_value_usd,
        SUM(p.unrealized_pnl_usd) AS unrealized_pnl_usd
FROM    capmkt.silver.positions  p
JOIN    capmkt.silver.securities s USING (symbol)
GROUP BY p.as_of_date, s.sector, s.country;

-- Client-level holdings (denormalised view for Power BI / Fabric Direct Lake)
CREATE OR REPLACE VIEW capmkt.gold.client_holdings AS
SELECT  c.client_id,
        c.name        AS client_name,
        c.client_type,
        c.country     AS client_country,
        a.account_id,
        a.base_currency,
        p.as_of_date,
        p.symbol,
        s.sector,
        s.industry,
        p.quantity,
        p.market_value_usd,
        p.unrealized_pnl_usd
FROM    capmkt.silver.positions  p
JOIN    capmkt.silver.accounts   a USING (account_id)
JOIN    capmkt.silver.clients    c USING (client_id)
JOIN    capmkt.silver.securities s USING (symbol);
