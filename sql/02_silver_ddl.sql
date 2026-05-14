-- =====================================================================
-- Silver layer DDL for the Capital Markets demo.
-- Schemas match the CSV files in pratpat/fabric-capital-markets-demo/data.
-- Delta does not allow PARTITIONED BY (expression), so timestamp-based
-- tables use a generated DATE column for partitioning.
-- =====================================================================

------------------------------------------------------------
-- Reference / Master Data
------------------------------------------------------------
CREATE OR REPLACE TABLE capmkt.silver.clients (
  client_id       STRING  NOT NULL,
  name            STRING,
  client_type     STRING,                 -- RETAIL, INSTITUTIONAL, HEDGE_FUND, PENSION, SOVEREIGN
  country         STRING,                 -- ISO-2
  kyc_tier        STRING,                 -- TIER_1..TIER_3
  risk_profile    STRING,                 -- CONSERVATIVE, MODERATE, AGGRESSIVE
  aum_usd         DECIMAL(20,2),
  onboarded_date  DATE
) USING DELTA;

CREATE OR REPLACE TABLE capmkt.silver.accounts (
  account_id      STRING NOT NULL,
  client_id       STRING NOT NULL,
  account_type    STRING,                 -- CASH, MARGIN, PRIME_BROKERAGE, CUSTODY
  base_currency   STRING,                 -- USD, EUR, GBP, JPY, HKD, CAD ...
  opened_date     DATE,
  status          STRING                  -- ACTIVE, CLOSED, FROZEN
) USING DELTA;

CREATE OR REPLACE TABLE capmkt.silver.traders (
  trader_id   STRING NOT NULL,
  name        STRING,
  desk        STRING,                     -- DERIVATIVES, QUANT, ETF, EQUITY_CASH, PROGRAM_TRADING
  region      STRING                      -- AMER, EMEA, APAC
) USING DELTA;

CREATE OR REPLACE TABLE capmkt.silver.securities (
  symbol     STRING NOT NULL,
  isin       STRING,
  cusip      STRING,
  name       STRING,
  sector     STRING,
  industry   STRING,
  exchange   STRING,                      -- MIC: XPAR, XNAS, XNYS, XLON, XETR, XTSE, XHKG, XTKS
  currency   STRING,
  country    STRING
) USING DELTA;

------------------------------------------------------------
-- Market Data
------------------------------------------------------------
CREATE OR REPLACE TABLE capmkt.silver.eod_prices (
  symbol      STRING NOT NULL,
  trade_date  DATE   NOT NULL,
  open        DECIMAL(18,6),
  high        DECIMAL(18,6),
  low         DECIMAL(18,6),
  close       DECIMAL(18,6),
  volume      BIGINT,
  adj_close   DECIMAL(18,6)
) USING DELTA
PARTITIONED BY (trade_date);

CREATE OR REPLACE TABLE capmkt.silver.market_quotes (
  symbol     STRING    NOT NULL,
  quote_ts   TIMESTAMP NOT NULL,
  quote_date DATE      GENERATED ALWAYS AS (CAST(quote_ts AS DATE)),
  bid        DECIMAL(18,6),
  ask        DECIMAL(18,6),
  bid_size   BIGINT,
  ask_size   BIGINT,
  venue      STRING
) USING DELTA
PARTITIONED BY (quote_date);

------------------------------------------------------------
-- Transactions
------------------------------------------------------------
CREATE OR REPLACE TABLE capmkt.silver.trades (
  trade_id     STRING    NOT NULL,
  trade_ts     TIMESTAMP NOT NULL,
  trade_date   DATE      GENERATED ALWAYS AS (CAST(trade_ts AS DATE)),
  symbol       STRING    NOT NULL,
  account_id   STRING    NOT NULL,
  trader_id    STRING,
  side         STRING,                    -- BUY, SELL
  quantity     DECIMAL(20,4),
  price        DECIMAL(18,6),
  notional     DECIMAL(22,4),
  venue        STRING,
  order_type   STRING,                    -- MARKET, LIMIT, STOP ...
  status       STRING                     -- FILLED, PARTIAL, CANCELLED
) USING DELTA
PARTITIONED BY (trade_date);

CREATE OR REPLACE TABLE capmkt.silver.positions (
  as_of_date           DATE   NOT NULL,
  account_id           STRING NOT NULL,
  symbol               STRING NOT NULL,
  quantity             DECIMAL(20,4),
  avg_cost             DECIMAL(18,6),
  market_value_usd     DECIMAL(22,4),
  unrealized_pnl_usd   DECIMAL(22,4)
) USING DELTA
PARTITIONED BY (as_of_date);
