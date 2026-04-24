-- KPI'S
SELECT
    SUM(transaction_amount) AS Total_Transaction_Volume, --TTV
    COUNT(transaction_id) AS Transaction_Count, --Total Transaction
    AVG(transaction_amount) AS Average_Transaction_Value --ATV 
FROM fact_transaction;


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
WITH customer_segments AS (
    SELECT 
        customer_account_balance,
        transaction_amount,
        CASE 
            WHEN customer_account_balance < 10000 THEN 'Low Balance (<10k)'
            WHEN customer_account_balance BETWEEN 10000 AND 100000 THEN 'Mid Balance (10k-100k)'
            ELSE 'High Balance (>100k)'
        END AS Balance_Tier
    FROM fact_transaction
)

SELECT 
    Balance_Tier,
    AVG(transaction_amount) AS Avg_Spend,
    COUNT(*) AS Transactions_Count,
SUM(transaction_amount) AS Total_Revenue
FROM customer_segments
GROUP BY Balance_Tier
ORDER BY Total_Revenue;

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
