USE WAREHOUSE policy_engine_silver_wh;
USE DATABASE policy_engine_db;

-- creating schema for silver layer
CREATE SCHEMA silver;
USE SCHEMA silver;

-- creating streams on raw table of the bronze layer to kee[ a track of any changes in the data

CREATE OR REPLACE STREAM claims_history_stream
ON TABLE POLICY_ENGINE_DB.BRONZE.CLAIMS_HISTORY_RAW;

CREATE OR REPLACE STREAM customer_master_stream
ON TABLE POLICY_ENGINE_DB.BRONZE.CUSTOMER_MASTER_RAW;

CREATE OR REPLACE STREAM kyc_records_stream
ON TABLE POLICY_ENGINE_DB.BRONZE.KYC_RECORDS_RAW;

CREATE OR REPLACE STREAM product_family_rules_stream
ON TABLE POLICY_ENGINE_DB.BRONZE.PRODUCT_FAMILY_RULES_RAW;

CREATE OR REPLACE STREAM region_mapping_stream
ON TABLE POLICY_ENGINE_DB.BRONZE.REGION_MAPPING_RAW;

CREATE OR REPLACE STREAM watchlist_stream
ON TABLE POLICY_ENGINE_DB.BRONZE.WATCHLIST_RAW;