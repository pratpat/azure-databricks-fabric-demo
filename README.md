# Azure Databricks + Microsoft Fabric — Capital Markets Demo

End-to-end demo showing how to land a capital-markets dataset in **Azure Databricks**
(Unity Catalog + Delta Lake, Medallion architecture) and publish curated tables to
**Microsoft Fabric** via OneLake shortcuts for Direct Lake / Power BI.

Source data is taken from
[`pratpat/fabric-capital-markets-demo`](https://github.com/pratpat/fabric-capital-markets-demo/tree/main/data)
(8 CSVs: clients, accounts, traders, securities, eod_prices, market_quotes, trades, positions).

## Repository layout

```
sql/
  01_create_catalog_schemas.sql   Unity Catalog + bronze/silver/gold schemas
  02_silver_ddl.sql               Silver Delta tables (matches CSV schemas)
  03_gold_ddl.sql                 Gold aggregates / views for BI
  04_optimize.sql                 OPTIMIZE + ZORDER maintenance
notebooks/
  load_csv_to_delta.py            Databricks notebook: CSV -> Silver Delta
```

## Quick start

1. **Provision** an Azure Databricks workspace with Unity Catalog enabled
   (Premium tier, DBR 14.x+ LTS recommended).
2. **Upload CSVs** from the source repo to a UC volume, e.g.
   `/Volumes/capmkt/bronze/raw/`.
3. Run the SQL scripts in order: `sql/01...sql` -> `sql/02...sql`.
4. Run the notebook `notebooks/load_csv_to_delta.py` to populate Silver tables.
5. Run `sql/03_gold_ddl.sql` to build Gold aggregates.
6. (Optional) Run `sql/04_optimize.sql` for layout optimisation.

## Publish to Microsoft Fabric

- Create a Fabric **Lakehouse**.
- Add a **OneLake shortcut** to the Unity Catalog external location backing
  `capmkt.gold.*`.
- Build a **Direct Lake** semantic model in Power BI on top of the shortcut.

## Notes

- Delta does not allow `PARTITIONED BY (expression)`; tables partitioned by date
  derived from a timestamp use a generated column (`trade_date`, `quote_date`).
- `clients.csv` and `securities.csv` contain embedded newlines inside quoted
  string fields - the loader uses `multiLine=True` and `escape='"'`.
