# Data Catalog - Gold Layer

The Gold layer is the business-level representation of the data, structured as a **star schema**
(two dimensions + one fact table) for analytics and reporting.

## gold.dim_customers
Customer master data, enriched with demographic and geographic data from the ERP.

| Column | Type | Description |
|---|---|---|
| customer_key | INT | Surrogate key (unique per row) |
| customer_id | INT | Business ID from CRM |
| customer_number | NVARCHAR(50) | Alphanumeric customer key (e.g. `AW00011000`) |
| first_name | NVARCHAR(50) | First name (trimmed) |
| last_name | NVARCHAR(50) | Last name (trimmed) |
| country | NVARCHAR(50) | Country of residence (`n/a` if unknown) |
| marital_status | NVARCHAR(50) | `Single`, `Married`, `n/a` |
| gender | NVARCHAR(50) | `Male`, `Female`, `n/a` (CRM first, ERP as fallback) |
| birthdate | DATE | Date of birth (invalid/future dates set to NULL) |
| create_date | DATE | Record creation date in CRM |

## gold.dim_products
Current product catalog with category attributes (history is not kept).

| Column | Type | Description |
|---|---|---|
| product_key | INT | Surrogate key |
| product_id | INT | Product ID from CRM |
| product_number | NVARCHAR(50) | Product key used in sales (e.g. `A087-15`) |
| product_name | NVARCHAR(100) | Product name |
| category_id | NVARCHAR(50) | Category code (e.g. `CO_RF`) |
| category | NVARCHAR(50) | Top-level category |
| subcategory | NVARCHAR(50) | Subcategory |
| maintenance | NVARCHAR(50) | Whether the product needs maintenance (`Yes`/`No`) |
| cost | INT | Base cost (0 if missing) |
| product_line | NVARCHAR(50) | `Mountain`, `Road`, `Touring`, `Other Sales`, `n/a` |
| start_date | DATE | Date the product version became available |

## gold.fact_sales
One row per order line.

| Column | Type | Description |
|---|---|---|
| order_number | NVARCHAR(50) | Order identifier |
| product_key | INT | FK -> dim_products |
| customer_key | INT | FK -> dim_customers |
| order_date | DATE | Order date (NULL if source value invalid) |
| shipping_date | DATE | Shipping date |
| due_date | DATE | Payment due date |
| sales_amount | INT | Line total (= quantity x price) |
| quantity | INT | Units ordered |
| price | INT | Unit price |

## Report views
- `gold.report_customers` - customer-level KPIs and segments (VIP / Regular / New).
- `gold.report_products` - product-level KPIs and segments (High / Mid / Low performer).

## Source -> Target mapping
| Source file | System | Bronze | Silver | Gold |
|---|---|---|---|---|
| cust_info.csv | CRM | crm_cust_info | crm_cust_info | dim_customers |
| prd_info.csv | CRM | crm_prd_info | crm_prd_info | dim_products |
| sales_details.csv | CRM | crm_sales_details | crm_sales_details | fact_sales |
| CUST_AZ12.csv | ERP | erp_cust_az12 | erp_cust_az12 | dim_customers |
| LOC_A101.csv | ERP | erp_loc_a101 | erp_loc_a101 | dim_customers |
| PX_CAT_G1V2.csv | ERP | erp_px_cat_g1v2 | erp_px_cat_g1v2 | dim_products |
