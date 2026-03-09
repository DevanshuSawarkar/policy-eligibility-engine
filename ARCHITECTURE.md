# 🏛️ Architecture & Technical Deep Dive

This document outlines the technical design, data flow, and SQL engineering principles behind the **Automated Policy Eligibility Engine**. The system is built entirely within Snowflake, leveraging its native cloud compute, storage, and orchestration capabilities.



The pipeline follows a strict **Medallion Architecture** (Bronze ➔ Silver ➔ Gold), ensuring data quality, idempotency, and auditability at every stage.

---

## 🥉 Phase 1: Ingestion & Bronze Layer (RAW)
**Objective:** Capture raw data from external sources robustly and dynamically without data loss.

### 1. Storage & Formats
Data arrives as monolithic CSV strings and semi-structured JSON payloads. It is initially loaded into an internal Snowflake Stage (`@policy_engine_stage`) encrypted with `SNOWFLAKE_SSE`. 
* **CSV:** Parsed using a custom file format that skips headers but captures the entire row as a single `VARCHAR` string to prevent parsing errors on ingestion.
* **JSON:** Ingested directly into Snowflake's native `VARIANT` data type, preserving the nested key-value structure.

### 2. Automated Task-Driven Ingestion
Instead of hardcoding filenames or relying on external orchestration tools (like Airflow), ingestion is fully autonomous using scheduled Snowflake Tasks combined with **Regex Pattern Matching**.

```sql
-- Example: Dynamic Ingestion Task
CREATE OR REPLACE TASK automate_bronze_customer_master
    WAREHOUSE = policy_engine_silver_wh
    SCHEDULE = '1 MINUTE'
AS
    COPY INTO bronze.customer_master_raw (RAW_DATA_LINE, FILE_NAME)
    FROM (
        SELECT $1, METADATA$FILENAME 
        FROM @policy_engine_stage/
    )
    PATTERN = '.*customer_master_.*\\.csv' -- Dynamically catches any new file version
    ON_ERROR = 'CONTINUE';
```

* **Auditability:** `METADATA$FILENAME` and `CURRENT_TIMESTAMP()` are permanently bound to the raw records.

## 🥈 Phase 2: Validation & Silver Layer (CDC)

**Objective:** Parse, cleanse, type-cast, and deduplicate data incrementally.

### 1. Change Data Capture (CDC)
Snowflake `STREAMS` are placed on top of all Bronze tables. The stream tracks the offset of exactly which rows have been inserted since the last pipeline run. This means the engine only processes delta loads, drastically reducing compute costs.

### 2. Idempotent Upserts (`MERGE` Logic)
Data extracted from the stream is parsed using `SPLIT_PART` (for CSVs) and dot-notation (for JSON). It is then merged into the Silver validated tables.

    ```sql
    -- Example: Idempotent MERGE
    MERGE INTO silver.customer_master_validated AS target
    USING (
        SELECT 
            SPLIT_PART(RAW_DATA, ',', 1)::VARCHAR AS CUSTOMER_ID,
            -- Inline Data Quality Rule: Graceful error handling for dates
            TRY_TO_DATE(SPLIT_PART(RAW_DATA, ',', 4), 'MM/DD/YYYY') AS DOB,
            FILE_NAME
        FROM bronze.customer_master_stream
        WHERE METADATA$ACTION = 'INSERT'
    ) AS source
    ON target.CUSTOMER_ID = source.CUSTOMER_ID
    WHEN MATCHED THEN UPDATE SET target.DOB = source.DOB
    WHEN NOT MATCHED THEN INSERT (CUSTOMER_ID, DOB) VALUES (source.CUSTOMER_ID, source.DOB);
    ```

### 3. Conditional Orchestration
The Silver tasks check the stream before waking up the virtual warehouse. If `SYSTEM$STREAM_HAS_DATA()` returns false, the task skips execution, costing zero credits.

## 🥇 Phase 3: Decision Engine & Gold Layer (CURATED)

**Objective:** Execute complex business logic and output structured, API-ready JSON decisions.

### 1. Polyglot UDFs (User-Defined Functions)
The business logic is too complex for standard SQL `CASE` statements. The engine uses a hybrid polyglot approach:

- SQL UDFs: Used for deterministic date math (e.g., calculating precise age from `DOB`).
- JavaScript UDFs: Used for complex, multi-variable branching logic.
    - Note: JavaScript natively uses double-precision floats. Snowflake `NUMBER` inputs are cast to `FLOAT` within the UDF boundary to prevent runtime type mismatch errors.

### 2. The Eligibility Matrix (Cross Join)
To determine exactly which products a customer qualifies for, the Gold orchestration task performs a `CROSS JOIN` between the unified customer profile and the `product_family_rules_validated` table. This creates an exhaustive N x M matrix, evaluating every customer against every policy.

### 3. Native JSON Generation
The final output must be consumed by downstream web applications. The engine uses `OBJECT_CONSTRUCT` to dynamically build a nested JSON payload explaining the evaluation.

    ```sql
    OBJECT_CONSTRUCT(
        'customer_name', c.FULL_NAME,
        'product_family', p.PRODUCT_FAMILY,
        'decision', DECISION_STATUS,
        'fraud_watchlist', COALESCE(w.ON_WATCHLIST, FALSE),
        'past_claims_count', COALESCE(ch.TOTAL_CLAIMS, 0)
    ) AS DECISION_DETAILS
    ```

## 🔐 Phase 4: Enterprise Security & Governance

**Objective:** Protect Personally Identifiable Information (PII) using Zero-Trust principles.

### 1. Role-Based Access Control (RBAC)
Custom roles (`ACCOUNTADMIN` ➔ `MANAGER` ➔ `SALESPERSON`) guarantee the Principle of Least Privilege. `SALESPERSON` roles are granted `USAGE` only on the Gold schema, physically preventing access to the raw CSV/JSON data.

### 2. Tag-Based Dynamic Data Masking
Instead of writing masking policies column-by-column, security is decoupled from the schema using **Snowflake Tags**.

1. A masking policy (generic_pii_mask) evaluates CURRENT_ROLE().
2. The policy is bound to a tag (pii_data_tag).
3. The tag is applied to sensitive columns across the entire database.

    ```sql
    -- Centralized Security Implementation
    ALTER TABLE silver.customer_master_validated 
        MODIFY COLUMN FULL_NAME SET TAG pii_data_tag = 'name',
               COLUMN MOBILE_NUMBER SET TAG pii_data_tag = 'phone',
               COLUMN EMAIL SET TAG pii_data_tag = 'email';
    ```

If a Manager runs a query, they see `919527123456`. If a Salesperson runs the exact same query, the compute engine dynamically masks it to `***MASKED_PII***` at runtime.