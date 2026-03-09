USE WAREHOUSE policy_engine_silver_wh;
USE DATABASE policy_engine_db;
USE SCHEMA gold;

USE ROLE ACCOUNTADMIN; -- You need admin rights to create roles and security policies

-- Create the roles
CREATE OR REPLACE ROLE MANAGER;
CREATE OR REPLACE ROLE SALESPERSON;
CREATE OR REPLACE ROLE DATA_USER;

-- Build a role hierarchy (Managers inherit Salesperson access)
GRANT ROLE SALESPERSON TO ROLE MANAGER;
GRANT ROLE MANAGER TO ROLE ACCOUNTADMIN;
GRANT ROLE DATA_USER TO ROLE ACCOUNTADMIN;


-- 1. Give everyone basic access to the database
GRANT USAGE ON DATABASE policy_engine_db TO ROLE SALESPERSON;
GRANT USAGE ON DATABASE policy_engine_db TO ROLE MANAGER;

-- 2. Grant Gold schema access to the Salesperson
GRANT USAGE ON SCHEMA policy_engine_db.gold TO ROLE SALESPERSON;
GRANT SELECT ON TABLE policy_engine_db.gold.DECISION_OUTPUT TO ROLE SALESPERSON;

-- 3. Grant Silver AND Gold schema access to the Manager
GRANT USAGE ON SCHEMA policy_engine_db.silver TO ROLE MANAGER;
GRANT SELECT ON ALL TABLES IN SCHEMA policy_engine_db.silver TO ROLE MANAGER;
GRANT USAGE ON SCHEMA policy_engine_db.gold TO ROLE MANAGER;
GRANT SELECT ON TABLE policy_engine_db.gold.DECISION_OUTPUT TO ROLE MANAGER;


-- Switch to Salesperson and look at the Silver table
USE ROLE SALESPERSON;
SELECT FULL_NAME, MOBILE_NUMBER FROM policy_engine_db.silver.customer_master_validated LIMIT 5;
-- Result: You will get an ERROR because they don't have access to the Silver layer! (Security working perfectly)

-- Switch to Manager and look at the same table
USE ROLE MANAGER;
SELECT FULL_NAME, MOBILE_NUMBER FROM policy_engine_db.silver.customer_master_validated LIMIT 5;
-- Result: It works! And because they are a Manager, they see the real phone numbers (e.g., 919527123456).

-- Switch to a basic user (if you granted them select)
USE ROLE DATA_USER;
SELECT FULL_NAME, MOBILE_NUMBER FROM policy_engine_db.silver.customer_master_validated LIMIT 5;
-- Result: They would see ***-***-3456.