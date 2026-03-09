USE WAREHOUSE policy_engine_silver_wh;
USE DATABASE policy_engine_db;
USE SCHEMA gold;

-- SQL UDF to calculate age
CREATE OR REPLACE FUNCTION calculate_age(dob DATE)
RETURNS NUMBER
AS
$$
  -- Calculates the age in years based on today's date
  TRUNC(DATEDIFF(month, dob, CURRENT_DATE()) / 12)
$$;

-- JavaScript UDF for the Rule Engine
CREATE OR REPLACE FUNCTION evaluate_eligibility (
    age FLOAT,
    kyc_status VARCHAR,
    region_risk VARCHAR,
    is_on_watchlist BOOLEAN,
    claims_count FLOAT
)
RETURNS VARCHAR
LANGUAGE JAVASCRIPT
AS
$$
    // NOTE: All variables must be referenced in UPPERCASE in the JS body

    // Rule 1: absolute rejections
    if (IS_ON_WATCHLIST === true) return 'REJECT'; // Fraud Risk
    if (AGE < 18) return 'REJECT'; // Underage

    // Rule 2: referrals (need human review)
    if (REGION_RISK.toUpperCase() === 'HIGH') return 'REFER'; // high-risk location
    
    // Safely upper-casing the KYC status for comparison
    let current_kyc = KYC_STATUS.toUpperCase();
    if (current_kyc === 'PARTIAL' || current_kyc === 'PENDING' || current_kyc === 'NONE') return 'REFER'; 
    
    if (CLAIMS_COUNT >= 2) return 'REFER'; // high claims history

    // Rule 3: clean profile
    return 'APPROVE';
$$;