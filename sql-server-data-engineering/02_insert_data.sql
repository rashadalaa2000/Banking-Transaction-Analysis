use fintech;

-------------------------------------------------

-- insert & don't duplicate
WITH CleanedCustomers AS (
    SELECT 
        CustomerID, 
        CustomerDOB, 
        DATEDIFF(YEAR, CustomerDOB, GETDATE()) AS customer_age,
        custgender, 
        custlocation,
        ROW_NUMBER() OVER (PARTITION BY CustomerID ORDER BY CustomerID) as row_num
    FROM bank_transactions
)
INSERT INTO dim_customers (customer_id, customer_bdate, customer_age, customer_gender, customer_location)
SELECT CustomerID, CustomerDOB, customer_age, custgender, custlocation
FROM CleanedCustomers
WHERE row_num = 1;  -- take the first

-- dim_customer #done#
--------------------------------------------------------------

INSERT INTO dim_date (date_key,full_date, month_name, week_number, day_name, quarter, is_weekend)
SELECT DISTINCT
    CAST(FORMAT(TransactionDate, 'yyyyMMdd') AS INT) AS date_key,
    TransactionDate, 
    DATENAME(MONTH, TransactionDate),
    DATEPART(WEEK, TransactionDate),
    DATENAME(WEEKDAY, TransactionDate),
    'Q' + CAST(DATEPART(QUARTER, TransactionDate) AS VARCHAR),
    CASE 
        WHEN DATENAME(WEEKDAY, TransactionDate) IN ('Saturday', 'Sunday') THEN 1 
        ELSE 0 
    END
FROM bank_transactions
WHERE TransactionDate IS NOT NULL; 
    


-- dim_date #done#
------------------------------------------------------------

INSERT INTO fact_transaction (
    transaction_id, 
    customer_id, 
    date_key, 
    transaction_amount, 
    transaction_time,
    customer_account_balance
)
SELECT 
    f.TransactionID, 
    f.CustomerID, 
    CAST(FORMAT(f.TransactionDate, 'yyyyMMdd') AS INT), 
    f.TransactionAmount_INR, 
    -- 131602 => 13.1602 => 1316.02 (16) => 02 ==> 13:16:02.0000000  & .0000000 > time(7) 
     TIMEFROMPARTS(
        (f.TransactionTime / 10000), --hour
        (f.TransactionTime / 100) % 100, --minute
        (f.TransactionTime % 100), -- second
        0, 0 
    ),
    f.CustAccountBalance
FROM bank_transactions f
INNER JOIN dim_customers c ON f.CustomerID = c.customer_id
INNER JOIN dim_date d ON CAST(FORMAT(f.TransactionDate, 'yyyyMMdd') AS INT) = d.date_key;
