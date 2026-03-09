USE WAREHOUSE policy_engine_bronze_wh;
USE DATABASE policy_engine_db;
USE SCHEMA bronze;

-- creating tables for storing raw data which will be used for audit and later for validation

-- claims_history (csv)
CREATE OR REPLACE TABLE claims_history_raw (
    raw_data VARCHAR, -- stores the whole csv line
    file_name VARCHAR,
    ingestion_timestamp TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP() -- TIMESTAMP_NTZ means 'Timestamp with no time zone' | by deafult the uploading timestamp is stored
);
    
-- customer_master (csv)
CREATE OR REPLACE TABLE customer_master_raw (
    raw_data VARCHAR,
    file_name VARCHAR,
    ingestion_timestamp TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- product_family_rules (csv)
CREATE OR REPLACE TABLE product_family_rules_raw (
    raw_data VARCHAR,
    file_name VARCHAR,
    ingestion_timestamp TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- region_mapping (csv)
CREATE OR REPLACE TABLE region_mapping_raw (
    raw_data VARCHAR,
    file_name VARCHAR,
    ingestion_timestamp TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- kyc_records (json)
CREATE OR REPLACE TABLE kyc_records_raw(
    json_payload VARIANT, -- snowflakes native json data type
    file_name VARCHAR,
    ingestion_timestamp TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- watchlist (json)
CREATE OR REPLACE TABLE watchlist_raw(
    json_payload VARIANT,
    file_name VARCHAR,
    ingestion_timestamp TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);