-- KPI'S
SELECT
    SUM(transaction_amount) AS Total_Transaction_Volume, --TTV
    COUNT(transaction_id) AS Transaction_Count, --Total Transaction
    AVG(transaction_amount) AS Average_Transaction_Value --ATV 
FROM fact_transaction;

-- Customer Segmentation & Behavior
WITH CustomerBase AS (
    SELECT 
        customer_id, 
        MIN(transaction_date) as first_date,
        COUNT(transaction_id) as tx_count,
        SUM(transaction_amount) as total_amt
    FROM fact_transaction
    GROUP BY customer_id
)
SELECT 
    CASE 
        WHEN first_date > '2016-08-15' THEN 'New Customer'
        ELSE 'Old Customer'
    END AS Category,
    COUNT(customer_id) AS Customer_Count,
    CAST(COUNT(customer_id) * 100.0 / SUM(COUNT(customer_id)) OVER() AS DECIMAL(10,2)) AS Customer_Percentage,
    SUM(tx_count) AS Total_Transactions,
    CAST(SUM(total_amt) AS DECIMAL(18,2)) AS Total_Volume,
    CAST(SUM(total_amt) / SUM(tx_count) AS DECIMAL(18,2)) AS Avg_Spend_Per_Tx
FROM CustomerBase
GROUP BY 
    CASE 
        WHEN first_date > '2016-08-15' THEN 'New Customer'
        ELSE 'Old Customer'
    END;
/* This ranking is non-academic and its validity is only relative, 
not a true reflection of the bank's growth because the data limitation*/

-- Transaction Density
SELECT 
    CAST(COUNT(transaction_id) * 1.0 / COUNT(DISTINCT customer_id) 
        AS DECIMAL(10,2)) AS Transactions_Per_Customer
FROM fact_transaction; 

-- High-Value Contribution
SELECT 
    COUNT(CASE WHEN transaction_amount > 10000 THEN 1 END) AS High_Value_Count,
    COUNT(*) AS Total_Count,
    CAST(COUNT(CASE WHEN transaction_amount > 10000 THEN 1 END) * 100.0 / COUNT(*) 
        AS DECIMAL(10,2)) AS High_Value_Ratio_Percent
FROM fact_transaction;



--TOP 10 city
SELECT 
	TOP 10 customer_location,
	SUM(transaction_amount) AS Total_Transaction_Volume,
	AVG(transaction_amount) AS Average_Transaction_Value ,
	COUNT(transaction_id) AS Transaction_Count
FROM fact_transaction ft
LEFT JOIN dim_customers dc
ON dc.customer_id = ft.customer_id
group by customer_location
order by Total_Transaction_Volume desc; -- Not Capital

-- Balance vs Spending
SELECT 
    CASE 
        WHEN customer_account_balance < 10000 THEN 'Low Balance (<10k)'
        WHEN customer_account_balance BETWEEN 10000 AND 100000 THEN 'Mid Balance (10k-100k)'
        ELSE 'High Balance (>100k)'
    END AS Balance_Tier,
    AVG(transaction_amount) AS Avg_Spend
FROM fact_transaction
GROUP BY 
    CASE 
        WHEN customer_account_balance < 10000 THEN 'Low Balance (<10k)'
        WHEN customer_account_balance BETWEEN 10000 AND 100000 THEN 'Mid Balance (10k-100k)'
        ELSE 'High Balance (>100k)'
    END; -- make sense

-- Gender Spending Pattern
SELECT
c.customer_gender,
    COUNT(f.transaction_id) AS Count,
    AVG(f.transaction_amount) AS Avg_Amount
FROM fact_transaction f
JOIN dim_customers c ON f.customer_id = c.customer_id
GROUP BY c.customer_gender; -- Male

-- Age Demographics
SELECT 
    CASE 
        WHEN c.customer_age < 25 THEN 'Youth'
        WHEN c.customer_age BETWEEN 25 AND 45 THEN 'Adults'
        WHEN c.customer_age BETWEEN 45 AND 60 THEN 'Middle-Aged'
        ELSE 'Seniors'
    END AS Age_Group,
    COUNT(*) AS Transaction_Count,
    SUM(transaction_amount) AS Total_Spent
FROM fact_transaction f
JOIN dim_customers c ON f.customer_id = c.customer_id
GROUP BY 
    CASE 
        WHEN c.customer_age < 25 THEN 'Youth'
        WHEN c.customer_age BETWEEN 25 AND 45 THEN 'Adults'
        WHEN c.customer_age BETWEEN 45 AND 60 THEN 'Middle-Aged'
        ELSE 'Seniors'
    END 
order by Transaction_Count DESC; -- Adulys

-- fraud detection
SELECT 
    customer_id, 
    transaction_date, 
    COUNT(*) AS Transactions_Per_Day,
    SUM(transaction_amount) AS Daily_Total
FROM fact_transaction   
GROUP BY customer_id, transaction_date
HAVING COUNT(*) > 5 AND SUM(transaction_amount) > 50000
ORDER BY Daily_Total DESC; -- secuared



-- Total contribution of Top 100 Customers
WITH RankedCustomers AS (
    SELECT 
        customer_id,
        SUM(transaction_amount) AS Total_Spend,
        ROW_NUMBER() OVER (ORDER BY SUM(transaction_amount) DESC) AS Rank_Position
    FROM fact_transaction
    GROUP BY customer_id
)
SELECT 
    'Top 100 Customers' AS Segment,
    COUNT(*) AS Customer_Count,
    SUM(Total_Spend) AS Segment_Volume,
    CAST(SUM(Total_Spend) * 100.0 / (SELECT SUM(transaction_amount) FROM fact_transaction) AS DECIMAL(10,2)) AS Total_Contribution_Percent
FROM RankedCustomers
WHERE Rank_Position <= 100;
-- Shows how much the top 100 people control out of the whole bank


-- Checking for Missing Values in key columns
SELECT 
    COUNT(*) - COUNT(c.customer_id) as Missing_Customer_IDs,
    COUNT(*) - COUNT(transaction_amount) as Missing_Amounts,
    COUNT(*) - COUNT(transaction_date) as Missing_Dates,
    COUNT(*) - COUNT(customer_location) as Missing_Locations
FROM fact_transaction f
LEFT JOIN dim_customers c ON f.customer_id = c.customer_id;
-- Ensuring data completeness


-- TOP 10 Transactions with Missing Locations (Data Quality Risk)
SELECT TOP 10
    f.transaction_id, 
    f.transaction_amount,
    f.customer_id
FROM fact_transaction f
LEFT JOIN dim_customers c ON f.customer_id = c.customer_id
WHERE c.customer_location IS NULL
ORDER BY f.transaction_amount DESC;
-- Checking the source of nulls

/* Summary of EDA Insights:

1. Hyper-Growth Engine: 
   63% of the active customer base are "New Customers" who joined mid-period, 
   contributing 59% of the Total Transaction Volume (979.5M INR).

2. High Stability & Low Risk: 
   The Top 100 customers control only 2.07% of the total volume. 
   This indicates a healthy, diversified retail bank with no dependency on single large entities.


3. Prime Demographics: 
   Adults (Aged 25-45) are the primary revenue drivers, 
   accounting for over 948 Million INR of the total volume.

4. High-Value Segment: 
   Only 2.27% of transactions exceed 10,000 INR, yet they significantly boost the TTV. 
   High-balance customers (>100k) spend 3x more per transaction than low-balance ones.

5. Gender Dominance: 
   Male customers significantly lead in both transaction frequency and total volume.

6. Data Quality & Audit:
   - 149 transactions missing location data (0.01% of total).
   - High-Value Impact: Top missing entries lead by T296851 (77,590 INR).
   - The Top 10 'Unknown' transactions alone account for ~157k INR, 
     highlighting a slight gap in high-value geographical tracking. 
*/