USE WAREHOUSE policy_engine_bronze_wh;
USE DATABASE policy_engine_db;
USE SCHEMA bronze;

-- Task to automate Customer Master ingestion

CREATE OR REPLACE TASK automate_claims_history_raw
    WAREHOUSE = policy_engine_silver_wh
    SCHEDULE = '1 MINUTE'
AS
    COPY INTO claims_history_raw (raw_data, file_name)
    FROM (
        SELECT
            $1, -- This represents the entire unbroken row of text
            METADATA$FILENAME -- This automatically grabs the name of the file
        FROM @policy_engine_stage/
    )
    PATTERN = '.*claims_history_.*\\.csv'
    FILE_FORMAT = (FORMAT_NAME = 'policy_engine_csv_raw_ff')
    ON_ERROR = 'CONTINUE'; -- Ensures the load doesn't fail if one row is corrupted
    

CREATE OR REPLACE TASK automate_customer_master_raw
    WAREHOUSE = policy_engine_silver_wh
    SCHEDULE = '1 MINUTE'
AS
    COPY INTO customer_master_raw (raw_data, file_name)
    FROM (
        SELECT
            $1,
            METADATA$FILENAME
        FROM @policy_engine_stage/
    )
    PATTERN = '.*customer_master_.*\\.csv'
    FILE_FORMAT = (FORMAT_NAME = 'policy_engine_csv_raw_ff')
    ON_ERROR = 'CONTINUE';


CREATE OR REPLACE TASK automate_product_family_rules_raw
    WAREHOUSE = policy_engine_silver_wh
    SCHEDULE = '1 MINUTE'
AS
    COPY INTO product_family_rules_raw (raw_data, file_name)
    FROM (
        SELECT
            $1,
            METADATA$FILENAME
        FROM @policy_engine_stage/
    )
    PATTERN = '.*product_family_rules_.*\\.csv'
    FILE_FORMAT = (FORMAT_NAME = 'policy_engine_csv_raw_ff')
    ON_ERROR = 'CONTINUE';


CREATE OR REPLACE TASK automate_region_mapping_raw
    WAREHOUSE = policy_engine_silver_wh
    SCHEDULE = '1 MINUTE'
AS
    COPY INTO region_mapping_raw (raw_data, file_name)
    FROM (
        SELECT
            $1,
            METADATA$FILENAME
        FROM @policy_engine_stage/
    )
    PATTERN = '.*region_mapping_.*\\.csv'
    FILE_FORMAT = (FORMAT_NAME = 'policy_engine_csv_raw_ff')
    ON_ERROR = 'CONTINUE';


CREATE OR REPLACE TASK automate_kyc_records_raw
    WAREHOUSE = policy_engine_silver_wh
    SCHEDULE = '1 MINUTE'
AS
    COPY INTO kyc_records_raw (json_payload, file_name)
    FROM (
        SELECT
            $1,
            METADATA$FILENAME
        FROM @policy_engine_stage/
    )
    PATTERN = '.*kyc_records_.*\\.csv'
    FILE_FORMAT = (FORMAT_NAME = 'policy_engine_json_ff')
    ON_ERROR = 'CONTINUE';


CREATE OR REPLACE TASK automate_watchlist_raw
    WAREHOUSE = policy_engine_silver_wh
    SCHEDULE = '1 MINUTE'
AS
    COPY INTO watchlist_raw (json_payload, file_name)
    FROM (
        SELECT
            $1,
            METADATA$FILENAME
        FROM @policy_engine_stage/
    )
    PATTERN = '.*watchlist_.*\\.csv'
    FILE_FORMAT = (FORMAT_NAME = 'policy_engine_json_ff')
    ON_ERROR = 'CONTINUE';