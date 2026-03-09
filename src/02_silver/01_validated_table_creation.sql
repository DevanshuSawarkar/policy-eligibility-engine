USE WAREHOUSE policy_engine_silver_wh;
USE DATABASE policy_engine_db;
USE SCHEMA silver;

-- creating clean and structured tables to store the data

CREATE OR REPLACE TABLE claims_history_validated (
    claim_id VARCHAR PRIMARY KEY,
    customer_id VARCHAR,
    claim_date DATE,
    claim_amount NUMBER,
    is_fraud BOOLEAN,
    product_family VARCHAR,
    file_name VARCHAR,
    validated_timestamp TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

CREATE OR REPLACE TABLE customer_master_validated (
    customer_id VARCHAR PRIMARY KEY,
    full_name VARCHAR,
    gender VARCHAR,
    dob DATE,
    mobile_number VARCHAR,
    email VARCHAR,
    region_risk VARCHAR,
    city VARCHAR,
    country VARCHAR,
    file_name VARCHAR,
    validated_timestamp TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

CREATE OR REPLACE TABLE kyc_records_validated (
    customer_id VARCHAR PRIMARY KEY,
    kyc_level VARCHAR,
    kyc_completed_on DATE,
    kyc_doc_type VARCHAR,
    kyc_doc_masked VARCHAR,
    file_name VARCHAR,
    validated_timestamp TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

CREATE OR REPLACE TABLE product_family_rules_validated (
    rule_id VARCHAR PRIMARY KEY,
    product_family VARCHAR,
    max_active_policies NUMBER,
    min_age NUMBER,
    require_kyc_level VARCHAR,
    sum_assured_threshold NUMBER,
    file_name VARCHAR,
    validated_timestamp TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

CREATE OR REPLACE TABLE region_mapping_validated (
    region_code VARCHAR PRIMARY KEY,
    city VARCHAR,
    state VARCHAR,
    country VARCHAR,
    risk_flag VARCHAR,
    file_name VARCHAR,
    validated_timestamp TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

CREATE OR REPLACE TABLE watchlist_validated (
    customer_id VARCHAR PRIMARY KEY,
    on_watchlist BOOLEAN,
    watch_reason VARCHAR,
    source VARCHAR,
    loaded_at TIMESTAMP_TZ,
    file_name VARCHAR,
    validated_timestamp TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);