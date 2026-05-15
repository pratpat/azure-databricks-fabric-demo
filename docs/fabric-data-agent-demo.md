# Fabric Data Agent — Capital Markets Data Hub Demo

End-to-end instructions for standing up a **Microsoft Fabric Data Agent** on top of the
Capital Markets Lakehouse built from this repo, so business users can ask natural-language
questions like *"What is the unrealized P&L by sector as of yesterday?"*.

---

## Prerequisites

- Fabric workspace assigned to a **F64+ capacity** (Data Agents require Copilot capacity).
- The Databricks pipeline from this repo has been run, producing the Gold tables:
  - `capmkt.gold.desk_pnl_daily`
  - `capmkt.gold.exposure_by_sector`
  - `capmkt.gold.client_holdings`
- A Fabric **Lakehouse** (e.g. `lh_capmkt`) with **OneLake shortcuts** to the Unity
  Catalog external location backing `capmkt.gold.*` and the Silver reference tables
  (`clients`, `accounts`, `securities`, `traders`).
- User has **Member or Admin** role on the workspace.

---

## Step 1 — Prepare the Lakehouse

1. In the Fabric workspace, open `lh_capmkt`.
2. Verify shortcuts resolve and tables are queryable in the SQL endpoint:
   ```sql
   SELECT TOP 5 * FROM capmkt_gold.exposure_by_sector;
   ```
3. Add **table descriptions** (Lakehouse > table > Properties) — the agent uses these
   as grounding context. Suggested descriptions:

   | Table | Description |
   |---|---|
   | `clients` | Master list of investing clients with KYC tier, country and AUM. |
   | `accounts` | Trading accounts owned by clients; type (CASH/MARGIN/PRIME_BROKERAGE/CUSTODY) and status. |
   | `securities` | Instrument master: symbol, ISIN/CUSIP, sector, industry, exchange MIC. |
   | `traders` | Internal traders with desk (DERIVATIVES/QUANT/ETF/...) and region. |
   | `eod_prices` | Daily OHLCV close prices per symbol. |
   | `market_quotes` | Intraday bid/ask quotes per symbol/venue. |
   | `trades` | Executed trades with price, quantity, notional, side, venue. |
   | `positions` | Daily account-level positions with market value and unrealized P&L (USD). |
   | `desk_pnl_daily` | Gold: daily net cash flow and gross notional by trading desk and region. |
   | `exposure_by_sector` | Gold: market value and unrealized P&L by sector and country. |
   | `client_holdings` | Gold: denormalized client -> account -> position view for BI. |

---

## Step 2 — Create the Data Agent

1. In the workspace, **+ New item** -> **Data agent** (Preview).
2. Name: `Capital Markets Insights`.
3. Description:
   > Natural-language access to capital markets positions, trades, P&L and client
   > exposures. Backed by the `lh_capmkt` Lakehouse.
4. Add data source -> **Lakehouse** -> select `lh_capmkt`.
5. Select tables to expose (recommended): `clients`, `accounts`, `securities`,
   `traders`, `positions`, `trades`, `desk_pnl_daily`, `exposure_by_sector`,
   `client_holdings`. Exclude `market_quotes` for v1 (high cardinality, low BI value).

---

## Step 3 — Add agent instructions

Paste the following into the agent's **Instructions** pane:

```text
You are a Capital Markets analytics assistant for portfolio managers, traders and risk officers.

Answer questions using ONLY the tables registered in the lh_capmkt Lakehouse.
Always:
- Express monetary values in USD unless the user asks otherwise; positions.market_value_usd
  and positions.unrealized_pnl_usd are already USD.
- Use positions.as_of_date for "as of" / "today" / "yesterday" questions; default to the
  MAX(as_of_date) when no date is given.
- For P&L by desk or region, prefer gold.desk_pnl_daily over recomputing from trades.
- For sector / country exposure, prefer gold.exposure_by_sector.
- For client-level views, prefer gold.client_holdings.
- When joining trades to traders, key on trader_id. When joining positions to clients,
  go positions -> accounts -> clients via account_id then client_id.
- Treat side='BUY' as cash outflow and side='SELL' as cash inflow when computing flows.
- Respect status filters: exclude accounts where status IN ('CLOSED') unless asked.
- If a query would return more than 1000 rows, summarize or top-N (default top 20)
  and tell the user.

Never:
- Invent symbols, clients or columns. If something is not in the schema, say so.
- Expose row-level PII beyond what the user already has access to via Fabric RLS.

Tone: concise, numeric, with a one-sentence interpretation after each result.
```

---

## Step 4 — Add example questions (few-shot grounding)

Add these as **example prompts** in the Data Agent designer:

1. *"Top 10 clients by total market value as of the latest date."*
2. *"What was the desk P&L yesterday by region?"*
3. *"Show unrealized P&L by GICS sector for the last available date."*
4. *"Which traders had the highest gross notional this month?"*
5. *"Total exposure to UK-listed securities, broken down by client type."*
6. *"List positions where unrealized P&L is worse than -1,000,000 USD."*
7. *"What percentage of total AUM is held in PRIME_BROKERAGE accounts?"*
8. *"Compare daily trade count between EQUITY_CASH and DERIVATIVES desks last week."*

For each example, run it once in the designer and **approve** the generated SQL so it
is used as a high-quality few-shot example.

---

## Step 5 — Publish and test

1. Click **Publish**.
2. Test in the **Chat** pane with the example prompts above.
3. Validate the generated SQL by expanding the **Steps** panel; fix instructions if
   the agent picks the wrong table (e.g. recomputes P&L from `trades` instead of using
   `desk_pnl_daily`).

---

## Step 6 — Consume the agent

- **Power BI** report: add a *Copilot* visual bound to the agent.
- **Teams**: share the agent URL; users can `@CapitalMarketsInsights` it in chats.
- **Custom app**: call the agent via the Fabric REST API:
  ```http
  POST https://api.fabric.microsoft.com/v1/workspaces/{wsId}/dataAgents/{agentId}/query
  {
    "question": "Top 10 clients by market value today"
  }
  ```

---

## Step 7 — Governance

- Apply **OLS / RLS** in the Lakehouse SQL endpoint for desk- or region-scoped users
  (e.g. APAC traders only see `traders.region = 'APAC'`).
- Enable **Purview** sensitivity labels on the Lakehouse; the Data Agent inherits them.
- Audit conversations via the workspace **Monitoring hub** -> *Copilot activity*.

---

## Demo runbook (5-minute talk track)

1. **Show the Lakehouse** — point out shortcut icon on Gold tables (zero data movement
   from Databricks Unity Catalog).
2. **Open the Data Agent chat** — ask: *"Top 5 desks by gross notional yesterday."*
   Expand Steps; show the generated SQL hits `gold.desk_pnl_daily`.
3. **Drill down** — *"Which traders contributed most to the QUANT desk number?"*
4. **Cross-domain** — *"For those traders' top 3 symbols, what's the current sector
   exposure?"* (joins `trades` -> `securities` -> `exposure_by_sector`).
5. **Governance** — switch to an APAC-only test user; same prompt now returns
   region-filtered results, proving RLS is honored end-to-end.
