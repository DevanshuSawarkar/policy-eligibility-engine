-- using bronze warehouse of XSMALL size
USE WAREHOUSE policy_engine_bronze_wh;

-- creating database for the project
CREATE DATABASE policy_engine_db;
USE DATABASE policy_engine_db;

-- creating schema for the bronze layer
CREATE SCHEMA bronze;
USE SCHEMA bronze;

-- creating internal stage for file upload
CREATE OR REPLACE STAGE policy_engine_stage
    DIRECTORY = (ENABLE = TRUE)
    ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE'); -- applying Snowflake Server-Side Encryption

-- creating file formats for .csv and .json
CREATE OR REPLACE FILE FORMAT policy_engine_csv_raw_ff
    TYPE = 'CSV'
    FIELD_DELIMITER = NONE  -- This is the magic trick to keep the line intact!
    SKIP_HEADER = 1
    NULL_IF = ('NULL', 'null', '');
    COMMENT = 'CSV file format for policy_engine_db internal stage policy_engine_stage';

CREATE OR REPLACE FILE FORMAT policy_engine_json_ff
    TYPE = JSON
    COMMENT = 'JSON file format for policy_engine_db internal stage policy_engine_stage';