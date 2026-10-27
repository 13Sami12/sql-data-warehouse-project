# Naming Conventions

## General
- `snake_case`, lowercase, English only. Avoid reserved words.

## Tables
- **Bronze / Silver:** `<sourcesystem>_<entity>` - e.g. `crm_cust_info`, `erp_loc_a101`.
- **Gold:** `<category>_<entity>` - `dim_` (dimension), `fact_` (fact), `report_` (reporting view).

## Columns
- Surrogate keys: `<entity>_key` (e.g. `customer_key`).
- Technical columns: `dwh_<name>` (e.g. `dwh_create_date`).

## Stored procedures
- `load_<layer>` - e.g. `bronze.load_bronze`, `silver.load_silver`.
