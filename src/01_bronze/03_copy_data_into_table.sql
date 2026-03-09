USE WAREHOUSE policy_engine_bronze_wh;
USE DATABASE policy_engine_db;
USE SCHEMA bronze;

-- loading raw data from stage into raw tbales of the bronze stage

-- load csv data

COPY INTO claims_history_raw (raw_data, file_name)
FROM (
    SELECT
        $1, -- This represents the entire unbroken row of text
        METADATA$FILENAME -- This automatically grabs the name of the file
    FROM @policy_engine_stage/claims_history_50.csv
)
FILE_FORMAT = (FORMAT_NAME = 'policy_engine_csv_raw_ff')
ON_ERROR = 'CONTINUE'; -- Ensures the load doesn't fail if one row is corrupted

COPY INTO customer_master_raw (raw_data, file_name)
FROM (
    SELECT
        $1,
        METADATA$FILENAME
    FROM @policy_engine_stage/customer_master_50.csv
)
FILE_FORMAT = (FORMAT_NAME = 'policy_engine_csv_raw_ff')
ON_ERROR = 'CONTINUE';

COPY INTO product_family_rules_raw (raw_data, file_name)
FROM (
    SELECT
        $1,
        METADATA$FILENAME
    FROM @policy_engine_stage/product_family_rules_50.csv
)
FILE_FORMAT = (FORMAT_NAME = 'policy_engine_csv_raw_ff')
ON_ERROR = 'CONTINUE';

COPY INTO region_mapping_raw (raw_data, file_name)
FROM (
    SELECT
        $1,
        METADATA$FILENAME
    FROM @policy_engine_stage/region_mapping_50.csv
)
FILE_FORMAT = (FORMAT_NAME = 'policy_engine_csv_raw_ff')
ON_ERROR = 'CONTINUE';

-- load json data

COPY INTO kyc_records_raw (json_payload, file_name)
FROM (
    SELECT
        $1,
        METADATA$FILENAME
    FROM @policy_engine_stage/kyc_records_501.json
)
FILE_FORMAT = (FORMAT_NAME = 'policy_engine_json_ff')
ON_ERROR = 'CONTINUE';

COPY INTO watchlist_raw (json_payload, file_name)
FROM (
    SELECT
        $1,
        METADATA$FILENAME
    FROM @policy_engine_stage/watchlist_501.json
)
FILE_FORMAT = (FORMAT_NAME = 'policy_engine_json_ff')
ON_ERROR = 'CONTINUE';