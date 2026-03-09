USE WAREHOUSE policy_engine_silver_wh;
USE DATABASE policy_engine_db;
USE SCHEMA silver;

-- writing MERGE statements. MERGE looks at the incoming data from the Stream. If the data already exists in the Silver table, it updates it. If it is new, it inserts it. This guarantees idempotency (no duplicates, no matter how many times you run it).

-- Because CSV is one long string, we use SPLIT_PART to grab the text between the commas.

MERGE INTO customer_master_validated AS target
USING (
    SELECT 
        SPLIT_PART(RAW_DATA, ',', 1)::VARCHAR AS CUSTOMER_ID,
        SPLIT_PART(RAW_DATA, ',', 2)::VARCHAR AS FULL_NAME,
        SPLIT_PART(RAW_DATA, ',', 3)::VARCHAR AS GENDER,
        -- SPLIT_PART(RAW_DATA, ',', 4)::VARCHAR AS DOB,
        TRY_TO_DATE(SPLIT_PART(RAW_DATA, ',', 4), 'MM/DD/YYYY') AS DOB,
        SPLIT_PART(RAW_DATA, ',', 5)::VARCHAR AS MOBILE_NUMBER,
        SPLIT_PART(RAW_DATA, ',', 6)::VARCHAR AS EMAIL,
        SPLIT_PART(RAW_DATA, ',', 7)::VARCHAR AS REGION_RISK,
        SPLIT_PART(RAW_DATA, ',', 8)::VARCHAR AS CITY,
        SPLIT_PART(RAW_DATA, ',', 9)::VARCHAR AS COUNTRY,
        FILE_NAME
    FROM customer_master_stream
    WHERE METADATA$ACTION = 'INSERT'
) AS source
ON target.CUSTOMER_ID = source.CUSTOMER_ID
WHEN MATCHED THEN
    UPDATE SET 
        target.FULL_NAME = source.FULL_NAME,
        target.GENDER = source.GENDER,
        target.DOB = source.DOB,
        target.MOBILE_NUMBER = source.MOBILE_NUMBER,
        target.EMAIL = source.EMAIL,
        target.REGION_RISK = source.REGION_RISK,
        target.CITY = source.CITY,
        target.COUNTRY = source.COUNTRY
WHEN NOT MATCHED THEN
    INSERT (CUSTOMER_ID, FULL_NAME, GENDER, DOB, MOBILE_NUMBER, EMAIL, REGION_RISK, CITY, COUNTRY, FILE_NAME)
    VALUES (source.CUSTOMER_ID, source.FULL_NAME, source.GENDER, source.DOB, source.MOBILE_NUMBER, source.EMAIL, source.REGION_RISK, source.CITY, source.COUNTRY, source.FILE_NAME);

MERGE INTO CLAIMS_HISTORY_VALIDATED AS target
USING (
    SELECT 
        SPLIT_PART(RAW_DATA, ',', 1)::VARCHAR AS CLAIM_ID,
        SPLIT_PART(RAW_DATA, ',', 2)::VARCHAR AS CUSTOMER_ID,
        -- SPLIT_PART(RAW_DATA, ',', 3)::DATE AS CLAIM_DATE,
        TRY_TO_DATE(SPLIT_PART(RAW_DATA, ',', 3), 'YYYY-MM-DD') AS CLAIM_DATE,
        SPLIT_PART(RAW_DATA, ',', 4)::NUMBER(38,2) AS CLAIM_AMOUNT,
        SPLIT_PART(RAW_DATA, ',', 5)::VARCHAR AS IS_FRAUD,
        SPLIT_PART(RAW_DATA, ',', 6)::VARCHAR AS PRODUCT_FAMILY,
        FILE_NAME
    FROM CLAIMS_HISTORY_STREAM
    WHERE METADATA$ACTION = 'INSERT'
) AS source
ON target.CLAIM_ID = source.CLAIM_ID
WHEN MATCHED THEN
    UPDATE SET 
        target.CUSTOMER_ID = source.CUSTOMER_ID,
        target.CLAIM_DATE = source.CLAIM_DATE,
        target.CLAIM_AMOUNT = source.CLAIM_AMOUNT,
        target.IS_FRAUD = source.IS_FRAUD,
        target.PRODUCT_FAMILY = source.PRODUCT_FAMILY
WHEN NOT MATCHED THEN
    INSERT (CLAIM_ID, CUSTOMER_ID, CLAIM_DATE, CLAIM_AMOUNT, IS_FRAUD, PRODUCT_FAMILY, FILE_NAME)
    VALUES (source.CLAIM_ID, source.CUSTOMER_ID, source.CLAIM_DATE, source.CLAIM_AMOUNT, source.IS_FRAUD, source.PRODUCT_FAMILY, source.FILE_NAME);

MERGE INTO REGION_MAPPING_VALIDATED AS target
USING (
    SELECT 
        SPLIT_PART(RAW_DATA, ',', 1)::VARCHAR AS REGION_CODE,
        SPLIT_PART(RAW_DATA, ',', 2)::VARCHAR AS CITY,
        SPLIT_PART(RAW_DATA, ',', 3)::VARCHAR AS STATE,
        SPLIT_PART(RAW_DATA, ',', 4)::VARCHAR AS COUNTRY,
        SPLIT_PART(RAW_DATA, ',', 5)::VARCHAR AS RISK_FLAG,
        FILE_NAME
    FROM REGION_MAPPING_STREAM
    WHERE METADATA$ACTION = 'INSERT'
) AS source
ON target.REGION_CODE = source.REGION_CODE
WHEN MATCHED THEN
    UPDATE SET 
        target.CITY = source.CITY,
        target.STATE = source.STATE,
        target.COUNTRY = source.COUNTRY,
        target.RISK_FLAG = source.RISK_FLAG
WHEN NOT MATCHED THEN
    INSERT (REGION_CODE, CITY, STATE, COUNTRY, RISK_FLAG, FILE_NAME)
    VALUES (source.REGION_CODE, source.CITY, source.STATE, source.COUNTRY, source.RISK_FLAG, source.FILE_NAME);

MERGE INTO PRODUCT_FAMILY_RULES_VALIDATED AS target
USING (
    SELECT 
        SPLIT_PART(RAW_DATA, ',', 1)::VARCHAR AS RULE_ID,
        SPLIT_PART(RAW_DATA, ',', 2)::VARCHAR AS PRODUCT_FAMILY,
        
        -- Safely handles empty strings for numbers
        NULLIF(TRIM(SPLIT_PART(RAW_DATA, ',', 3)), '')::NUMBER AS MAX_ACTIVE_POLICIES,
        
        TRY_TO_NUMBER(TRIM(SPLIT_PART(RAW_DATA, ',', 4))) AS MIN_AGE,
        SPLIT_PART(RAW_DATA, ',', 5)::VARCHAR AS REQUIRE_KYC_LEVEL,
        
        -- Safely handles empty strings for numbers
        NULLIF(TRIM(SPLIT_PART(RAW_DATA, ',', 6)), '')::NUMBER(38,2) AS SUM_ASSURED_THRESHOLD,
        
        FILE_NAME
    FROM PRODUCT_FAMILY_RULES_STREAM
    WHERE METADATA$ACTION = 'INSERT' 
      AND TRIM(RAW_DATA) != '' -- Ignores empty rows at the end of the CSV
) AS source
ON target.RULE_ID = source.RULE_ID
WHEN MATCHED THEN
    UPDATE SET 
        target.PRODUCT_FAMILY = source.PRODUCT_FAMILY,
        target.MAX_ACTIVE_POLICIES = source.MAX_ACTIVE_POLICIES,
        target.MIN_AGE = source.MIN_AGE,
        target.REQUIRE_KYC_LEVEL = source.REQUIRE_KYC_LEVEL,
        target.SUM_ASSURED_THRESHOLD = source.SUM_ASSURED_THRESHOLD
WHEN NOT MATCHED THEN
    INSERT (RULE_ID, PRODUCT_FAMILY, MAX_ACTIVE_POLICIES, MIN_AGE, REQUIRE_KYC_LEVEL, SUM_ASSURED_THRESHOLD, FILE_NAME)
    VALUES (source.RULE_ID, source.PRODUCT_FAMILY, source.MAX_ACTIVE_POLICIES, source.MIN_AGE, source.REQUIRE_KYC_LEVEL, source.SUM_ASSURED_THRESHOLD, source.FILE_NAME);

-- JSON

MERGE INTO KYC_RECORDS_VALIDATED AS target
USING (
    SELECT 
        JSON_PAYLOAD:customer_id::VARCHAR AS CUSTOMER_ID,
        JSON_PAYLOAD:kyc_level::VARCHAR AS KYC_LEVEL,
        -- JSON_PAYLOAD:kyc_completed_on::DATE AS KYC_COMPLETED_ON,
        TRY_TO_DATE(JSON_PAYLOAD:kyc_completed_on::VARCHAR, 'YYYY-MM-DD') AS KYC_COMPLETED_ON,
        JSON_PAYLOAD:kyc_doc_type::VARCHAR AS KYC_DOC_TYPE,
        JSON_PAYLOAD:kyc_doc_masked::VARCHAR AS KYC_DOC_MASKED,
        FILE_NAME
    FROM KYC_RECORDS_STREAM
    WHERE METADATA$ACTION = 'INSERT'
) AS source
ON target.CUSTOMER_ID = source.CUSTOMER_ID
WHEN MATCHED THEN
    UPDATE SET 
        target.KYC_LEVEL = source.KYC_LEVEL,
        target.KYC_COMPLETED_ON = source.KYC_COMPLETED_ON,
        target.KYC_DOC_TYPE = source.KYC_DOC_TYPE,
        target.KYC_DOC_MASKED = source.KYC_DOC_MASKED
WHEN NOT MATCHED THEN
    INSERT (CUSTOMER_ID, KYC_LEVEL, KYC_COMPLETED_ON, KYC_DOC_TYPE, KYC_DOC_MASKED, FILE_NAME)
    VALUES (source.CUSTOMER_ID, source.KYC_LEVEL, source.KYC_COMPLETED_ON, source.KYC_DOC_TYPE, source.KYC_DOC_MASKED, source.FILE_NAME);

MERGE INTO WATCHLIST_VALIDATED AS target
USING (
    SELECT 
        JSON_PAYLOAD:customer_id::VARCHAR AS CUSTOMER_ID,
        JSON_PAYLOAD:on_watchlist::BOOLEAN AS ON_WATCHLIST,
        JSON_PAYLOAD:watch_reason::VARCHAR AS WATCH_REASON,
        JSON_PAYLOAD:source::VARCHAR AS SOURCE,
        -- JSON_PAYLOAD:loaded_at::VARCHAR AS LOADED_AT,
        -- Replace the LOADED_AT line in your WATCHLIST_VALIDATED merge with this:
        TRY_TO_TIMESTAMP(JSON_PAYLOAD:loaded_at::VARCHAR) AS LOADED_AT,
        FILE_NAME
    FROM WATCHLIST_STREAM
    WHERE METADATA$ACTION = 'INSERT'
) AS source
ON target.CUSTOMER_ID = source.CUSTOMER_ID
WHEN MATCHED THEN
    UPDATE SET 
        target.ON_WATCHLIST = source.ON_WATCHLIST,
        target.WATCH_REASON = source.WATCH_REASON,
        target.SOURCE = source.SOURCE,
        target.LOADED_AT = source.LOADED_AT
WHEN NOT MATCHED THEN
    INSERT (CUSTOMER_ID, ON_WATCHLIST, WATCH_REASON, SOURCE, LOADED_AT, FILE_NAME)
    VALUES (source.CUSTOMER_ID, source.ON_WATCHLIST, source.WATCH_REASON, source.SOURCE, source.LOADED_AT, source.FILE_NAME);