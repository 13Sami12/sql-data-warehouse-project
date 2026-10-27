# Data Quality Issues & Cleansing Rules (Silver layer)

| Table | Issue found | Rule applied |
|---|---|---|
| crm_cust_info | Duplicate customers, NULL id | Keep latest row per `cst_id` (`ROW_NUMBER`), drop NULL ids |
| crm_cust_info | Leading/trailing spaces | `TRIM` |
| crm_cust_info | Coded values (`M`,`F`,`S`) / blanks | Map to full words, else `n/a` |
| crm_prd_info | Composite `prd_key` | Split into `cat_id` (first 5 chars, `-` -> `_`) and `prd_key` |
| crm_prd_info | NULL cost | `ISNULL(prd_cost, 0)` |
| crm_prd_info | End date earlier than start date | Recompute: next version's start date - 1 day (`LEAD`) |
| crm_prd_info | Coded product line | Map to `Mountain/Road/Touring/Other Sales/n/a` |
| crm_sales_details | Dates stored as INT, `0` or wrong length | Cast to `DATE`, else NULL |
| crm_sales_details | Sales NULL / negative / != qty x price | Recalculate `sales = quantity * ABS(price)` |
| crm_sales_details | Price NULL / <= 0 | `price = sales / quantity` |
| erp_cust_az12 | `NAS` prefix on customer id | Strip prefix |
| erp_cust_az12 | Future birthdates | Set to NULL |
| erp_cust_az12 | Gender variants (`Male`, `F`, blank) | Normalize to `Male/Female/n/a` |
| erp_loc_a101 | `-` inside customer id | Remove |
| erp_loc_a101 | Country codes (`DE`, `US`, `USA`) / blanks | Normalize to full country name / `n/a` |
