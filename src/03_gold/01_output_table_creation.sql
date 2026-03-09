USE WAREHOUSE policy_engine_silver_wh;
USE DATABASE policy_engine_db;
CREATE SCHEMA gold;
USE SCHEMA gold;

-- create the decision output table
CREATE OR REPLACE TABLE decision_output (
    customer_id VARCHAR PRIMARY KEY,
    product_family VARCHAR,
    decision_status VARCHAR, -- will hold APPROVE, REFER or REJECT
    decision_details VARIANT, -- will hold full JSON explanation
    evaluated_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);