-- Maintenance: layout optimisation for query performance.
OPTIMIZE capmkt.silver.trades        ZORDER BY (symbol, account_id);
OPTIMIZE capmkt.silver.positions     ZORDER BY (account_id, symbol);
OPTIMIZE capmkt.silver.market_quotes ZORDER BY (symbol);
OPTIMIZE capmkt.silver.eod_prices    ZORDER BY (symbol);
