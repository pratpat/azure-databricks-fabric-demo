# Databricks notebook source
# MAGIC %md
# MAGIC # Load Capital Markets CSVs into Silver Delta tables
# MAGIC
# MAGIC Source data: https://github.com/pratpat/fabric-capital-markets-demo/tree/main/data
# MAGIC
# MAGIC Prerequisites:
# MAGIC 1. Run `sql/01_create_catalog_schemas.sql`
# MAGIC 2. Run `sql/02_silver_ddl.sql`
# MAGIC 3. Upload the 8 CSVs to a Unity Catalog volume (default below) or ADLS Gen2.

# COMMAND ----------

RAW = "/Volumes/capmkt/bronze/raw"  # adjust if you uploaded to a different path

files = {
    "clients":       "clients.csv",
    "accounts":      "accounts.csv",
    "traders":       "traders.csv",
    "securities":    "securities.csv",
    "eod_prices":    "eod_prices.csv",
    "market_quotes": "market_quotes.csv",
    "trades":        "trades.csv",
    "positions":     "positions.csv",
}

# COMMAND ----------

for tbl, fname in files.items():
    print(f"Loading {fname} -> capmkt.silver.{tbl}")
    df = (spark.read
            .option("header", True)
            .option("inferSchema", True)
            .option("multiLine", True)   # clients.csv / securities.csv have embedded newlines
            .option("escape", '"')
            .csv(f"{RAW}/{fname}"))

    # Drop generated columns from the dataframe before writing (Delta computes them)
    for gen_col in ("trade_date", "quote_date"):
        if gen_col in df.columns:
            df = df.drop(gen_col)

    (df.write
        .mode("overwrite")
        .option("overwriteSchema", "true")
        .saveAsTable(f"capmkt.silver.{tbl}"))

# COMMAND ----------

# MAGIC %sql
# MAGIC SELECT 'clients'       AS tbl, COUNT(*) AS rows FROM capmkt.silver.clients       UNION ALL
# MAGIC SELECT 'accounts',           COUNT(*)          FROM capmkt.silver.accounts      UNION ALL
# MAGIC SELECT 'traders',            COUNT(*)          FROM capmkt.silver.traders       UNION ALL
# MAGIC SELECT 'securities',         COUNT(*)          FROM capmkt.silver.securities    UNION ALL
# MAGIC SELECT 'eod_prices',         COUNT(*)          FROM capmkt.silver.eod_prices    UNION ALL
# MAGIC SELECT 'market_quotes',      COUNT(*)          FROM capmkt.silver.market_quotes UNION ALL
# MAGIC SELECT 'trades',             COUNT(*)          FROM capmkt.silver.trades        UNION ALL
# MAGIC SELECT 'positions',          COUNT(*)          FROM capmkt.silver.positions;
