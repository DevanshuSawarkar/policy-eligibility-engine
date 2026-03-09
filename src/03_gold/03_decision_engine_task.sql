USE WAREHOUSE policy_engine_silver_wh;
USE DATABASE policy_engine_db;
USE SCHEMA gold;

-- CREATE OR REPLACE TASK decision_engine_task
--     WAREHOUSE = policy_engine_silver_wh
--     SCHEDULE = '5 MINUTE'
-- AS
-- MERGE INTO gold.DECISION_OUTPUT AS target
-- USING (
--     SELECT 
--         c.CUSTOMER_ID,
        
--         -- Apply the UDF to get the final status
--         gold.evaluate_eligibility(
--             gold.calculate_age(c.DOB), 
--             COALESCE(k.KYC_LEVEL, 'NONE'), 
--             COALESCE(r.RISK_FLAG, 'LOW'), 
--             COALESCE(w.ON_WATCHLIST, FALSE), 
--             COALESCE(ch.TOTAL_CLAIMS, 0)
--         ) AS DECISION_STATUS,
        
--         -- Pack all the reasons into a perfect JSON Object!
--         OBJECT_CONSTRUCT(
--             'customer_name', c.FULL_NAME,
--             'age', gold.calculate_age(c.DOB),
--             'kyc_status', COALESCE(k.KYC_LEVEL, 'NONE'),
--             'region_risk', COALESCE(r.RISK_FLAG, 'LOW'),
--             'fraud_watchlist', COALESCE(w.ON_WATCHLIST, FALSE),
--             'past_claims_count', COALESCE(ch.TOTAL_CLAIMS, 0)
--         ) AS DECISION_DETAILS

--     FROM silver.customer_master_validated c
--     LEFT JOIN silver.kyc_records_validated k ON c.CUSTOMER_ID = k.CUSTOMER_ID
--     LEFT JOIN silver.region_mapping_validated r ON c.CITY = r.CITY
--     LEFT JOIN silver.watchlist_validated w ON c.CUSTOMER_ID = w.CUSTOMER_ID
    
--     -- Subquery to quickly count how many claims they've had
--     LEFT JOIN (
--         SELECT CUSTOMER_ID, COUNT(*) AS TOTAL_CLAIMS 
--         FROM silver.claims_history_validated 
--         GROUP BY CUSTOMER_ID
--     ) ch ON c.CUSTOMER_ID = ch.CUSTOMER_ID
-- ) AS source
-- ON target.CUSTOMER_ID = source.CUSTOMER_ID

-- -- If they already exist, update their decision
-- WHEN MATCHED THEN 
--     UPDATE SET 
--         target.DECISION_STATUS = source.DECISION_STATUS,
--         target.DECISION_DETAILS = source.DECISION_DETAILS,
--         target.EVALUATED_AT = CURRENT_TIMESTAMP()

-- -- If it's a new customer, insert them
-- WHEN NOT MATCHED THEN
--     INSERT (CUSTOMER_ID, DECISION_STATUS, DECISION_DETAILS)
--     VALUES (source.CUSTOMER_ID, source.DECISION_STATUS, source.DECISION_DETAILS);

CREATE OR REPLACE TASK decision_engine_task
    WAREHOUSE = policy_engine_silver_wh
    SCHEDULE = '5 MINUTE'
AS
MERGE INTO gold.DECISION_OUTPUT AS target
USING (
    SELECT 
        c.CUSTOMER_ID,
        p.PRODUCT_FAMILY, -- Added the Product Family!
        
        -- Apply the UDF to get the final status
        gold.evaluate_eligibility(
            gold.calculate_age(c.DOB), 
            COALESCE(k.KYC_LEVEL, 'NONE'), 
            COALESCE(r.RISK_FLAG, 'LOW'), 
            COALESCE(w.ON_WATCHLIST, FALSE), 
            COALESCE(ch.TOTAL_CLAIMS, 0)
        ) AS DECISION_STATUS,
        
        -- Pack all the reasons into a perfect JSON Object!
        OBJECT_CONSTRUCT(
            'customer_name', c.FULL_NAME,
            'product_family', p.PRODUCT_FAMILY, -- Added to the JSON output!
            'age', gold.calculate_age(c.DOB),
            'kyc_status', COALESCE(k.KYC_LEVEL, 'NONE'),
            'region_risk', COALESCE(r.RISK_FLAG, 'LOW'),
            'fraud_watchlist', COALESCE(w.ON_WATCHLIST, FALSE),
            'past_claims_count', COALESCE(ch.TOTAL_CLAIMS, 0)
        ) AS DECISION_DETAILS

    FROM silver.customer_master_validated c
    
    -- THE MAGIC FIX: This evaluates every customer against every product rule
    CROSS JOIN silver.product_family_rules_validated p 
    
    LEFT JOIN silver.kyc_records_validated k ON c.CUSTOMER_ID = k.CUSTOMER_ID
    LEFT JOIN silver.region_mapping_validated r ON c.CITY = r.CITY
    LEFT JOIN silver.watchlist_validated w ON c.CUSTOMER_ID = w.CUSTOMER_ID
    
    -- Subquery to quickly count how many claims they've had
    LEFT JOIN (
        SELECT CUSTOMER_ID, COUNT(*) AS TOTAL_CLAIMS 
        FROM silver.claims_history_validated 
        GROUP BY CUSTOMER_ID
    ) ch ON c.CUSTOMER_ID = ch.CUSTOMER_ID
) AS source

-- We now merge on BOTH the Customer and the Product Family
ON target.CUSTOMER_ID = source.CUSTOMER_ID AND target.PRODUCT_FAMILY = source.PRODUCT_FAMILY

-- If this customer/product combo already exists, update their decision
WHEN MATCHED THEN 
    UPDATE SET 
        target.DECISION_STATUS = source.DECISION_STATUS,
        target.DECISION_DETAILS = source.DECISION_DETAILS,
        target.EVALUATED_AT = CURRENT_TIMESTAMP()

-- If it's a new evaluation, insert them
WHEN NOT MATCHED THEN
    INSERT (CUSTOMER_ID, PRODUCT_FAMILY, DECISION_STATUS, DECISION_DETAILS)
    VALUES (source.CUSTOMER_ID, source.PRODUCT_FAMILY, source.DECISION_STATUS, source.DECISION_DETAILS);

ALTER TASK decision_engine_task RESUME;

-- Forces the task to ignore the schedule and run right this second
EXECUTE TASK decision_engine_task;

SELECT * FROM gold.DECISION_OUTPUT;