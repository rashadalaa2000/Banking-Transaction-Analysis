-- Check Medain
SELECT top 1
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY customer_account_balance) OVER () AS median_cab
FROM fact_transaction; -- 16792.18 => Medain 


-- 1. CustAccountBalance NULLs
UPDATE fact_transaction
SET customer_account_balance = 16792.18 -- Medain 
WHERE customer_account_balance IS NULL;

-- 2. clear unlogical value
UPDATE dim_customers
SET 
    customer_age = NULL,
    customer_bdate = NULL
WHERE customer_age < 16 OR customer_age > 100;


-- Check
SELECT
    SUM(CASE WHEN CustAccountBalance IS NULL THEN 1 ELSE 0 END) AS balance_nulls,
    SUM(CASE WHEN CustomerDOB IS NULL THEN 1 ELSE 0 END)        AS dob_nulls
FROM bank_transactions;


-- 3. REPLACE T WITH NULL
UPDATE dim_customers
SET customer_gender = NULL
WHERE customer_gender = 'T';


-- Check
SELECT 
    DISTINCT customer_gender,
    COUNT(*) AS count_value
FROM dim_customers
GROUP BY customer_gender;
