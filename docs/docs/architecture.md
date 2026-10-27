# Architecture - Medallion (Bronze / Silver / Gold)

```mermaid
flowchart LR
    subgraph Sources
        CRM[(CRM CSV<br/>cust_info, prd_info, sales_details)]
        ERP[(ERP CSV<br/>CUST_AZ12, LOC_A101, PX_CAT_G1V2)]
    end
    subgraph DataWarehouse [SQL Server - DataWarehouse]
        B[Bronze<br/>raw tables<br/>BULK INSERT, truncate+load]
        S[Silver<br/>cleansed & standardized<br/>stored procedure]
        G[Gold<br/>star schema views<br/>dim_customers, dim_products, fact_sales]
    end
    CRM --> B
    ERP --> B
    B --> S --> G
    G --> BI[SQL analytics<br/>& reports]
```

| Layer | Object type | Load | Transformations | Purpose |
|---|---|---|---|---|
| Bronze | Tables | Full (truncate & insert) | None | Raw copy, traceability, debugging |
| Silver | Tables | Full (truncate & insert) | Cleansing, standardization, derived columns | Trusted, consistent data |
| Gold | Views | n/a | Integration, business rules, star schema | Analytics & reporting |

## Data model (Gold)

```mermaid
erDiagram
    dim_customers ||--o{ fact_sales : customer_key
    dim_products  ||--o{ fact_sales : product_key
    dim_customers {
        int customer_key PK
        int customer_id
        string customer_number
        string first_name
        string last_name
        string country
        string marital_status
        string gender
        date birthdate
        date create_date
    }
    dim_products {
        int product_key PK
        int product_id
        string product_number
        string product_name
        string category
        string subcategory
        string maintenance
        int cost
        string product_line
        date start_date
    }
    fact_sales {
        string order_number
        int product_key FK
        int customer_key FK
        date order_date
        date shipping_date
        date due_date
        int sales_amount
        int quantity
        int price
    }
```

## Integration model (how sources join)

```mermaid
flowchart TD
    ci[crm_cust_info.cst_key] --- ca[erp_cust_az12.cid]
    ci --- la[erp_loc_a101.cid]
    pn[crm_prd_info.cat_id] --- pc[erp_px_cat_g1v2.id]
    sd[crm_sales_details.sls_prd_key] --- pn2[crm_prd_info.prd_key]
    sd2[crm_sales_details.sls_cust_id] --- ci2[crm_cust_info.cst_id]
```
