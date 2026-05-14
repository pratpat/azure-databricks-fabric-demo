-- Create Unity Catalog catalog and medallion schemas for the
-- Capital Markets demo (data sourced from pratpat/fabric-capital-markets-demo).

CREATE CATALOG IF NOT EXISTS capmkt;

CREATE SCHEMA IF NOT EXISTS capmkt.bronze;
CREATE SCHEMA IF NOT EXISTS capmkt.silver;
CREATE SCHEMA IF NOT EXISTS capmkt.gold;

USE CATALOG capmkt;
