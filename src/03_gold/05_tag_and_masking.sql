USE WAREHOUSE policy_engine_silver_wh;
USE DATABASE policy_engine_db;
USE SCHEMA gold;

-- Create a tag for Personally Identifiable Information
CREATE OR REPLACE TAG pii_data_tag;

CREATE OR REPLACE MASKING POLICY generic_pii_mask AS (val VARCHAR) RETURNS VARCHAR ->
    CASE
        -- Managers and Admins see the real data
        WHEN CURRENT_ROLE() IN ('MANAGER', 'ACCOUNTADMIN') THEN val

        -- everyone else sees a masked version
        ELSE '***MASSKED_PII***'
    END;

ALTER TAG pii_data_tag SET MASKING POLICY generic_pii_mask;

-- Apply the tag to Name, Phone, and Email in a single command!
ALTER TABLE silver.customer_master_validated 
    MODIFY COLUMN FULL_NAME SET TAG pii_data_tag = 'name',
           COLUMN MOBILE_NUMBER SET TAG pii_data_tag = 'phone',
           COLUMN EMAIL SET TAG pii_data_tag = 'email';


USE ROLE MANAGER;
SELECT * FROM silver.customer_master_validated;

USE ROLE SALESPERSON;
SELECT * FROM silver.customer_master_validated;

USE ROLE DATA_USER;
SELECT * FROM silver.customer_master_validated;