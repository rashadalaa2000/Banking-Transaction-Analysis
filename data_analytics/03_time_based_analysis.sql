-- hourly traffic analysis
SELECT 
    DATEPART(HOUR, transaction_time) AS Transaction_Hour,
    COUNT(*) AS Total_Transactions
FROM fact_transaction
GROUP BY DATEPART(HOUR, transaction_time)
ORDER BY Total_Transactions DESC; -- 5 => 9 PM & if IT department will do update should be in 2 => 6 am


-- day_state
WITH DayPerformance AS (
    SELECT 
        d.day_name,
        -- Use day_of_week for sorting only
        MIN(d.week_number) as day_order, 
        COUNT(f.transaction_id) AS Transaction_Count,
        SUM(f.transaction_amount) AS Total_Money_Volume,
        AVG(f.transaction_amount) AS Avg_Transaction_Value
    FROM fact_transaction f
    JOIN dim_date d ON f.date_key = d.date_key
    GROUP BY d.day_name -- Group by day name to collapse the 55 days into 7
)
SELECT 
    day_name,
    Transaction_Count,
    -- Formatting numbers for a cleaner look in the presentation
    FORMAT(Total_Money_Volume, 'N0') AS Total_Volume_INR, 
    FORMAT(Avg_Transaction_Value, 'N2') AS Avg_Transaction_Value,
    -- Calculating the percentage of total volume for each day
    CAST(Total_Money_Volume * 100.0 / SUM(Total_Money_Volume) OVER() AS DECIMAL(10,2)) AS Revenue_Share_Percent
FROM DayPerformance
ORDER BY Total_Money_Volume DESC; -- Order by the most profitable day


-- Transaction Value Pattern by Day of Week
SELECT 
    d.day_name,
    -- Get the highest single transaction amount
    MAX(f.transaction_amount)  AS Largest_Single_Transaction,
    -- Get the average to see the general behavior
    AVG(f.transaction_amount) AS Average_Transaction_Value
FROM fact_transaction f
JOIN dim_date d ON f.date_key = d.date_key
GROUP BY d.day_name
ORDER BY Largest_Single_Transaction DESC;
--Is That B2B transaction in Working days?

SELECT TOP 10 
    f.transaction_id, 
    f.transaction_amount, 
    d.day_name,
    f.transaction_time
FROM fact_transaction f
JOIN dim_date d ON f.date_key = d.date_key
ORDER BY f.transaction_amount DESC;
-- 70 % not in work time 
-- flexible transaction in after work hours

WITH WeekdayTimeAnalysis AS (
    SELECT 
        f.transaction_id,
        f.transaction_amount,
        f.transaction_time,
        CASE 
            WHEN f.transaction_time BETWEEN '09:00:00' AND '18:00:00' THEN 'Standard Business Hours'
            ELSE 'After-Hours (Off-Peak)'
        END AS Time_Segment
    FROM fact_transaction f
    JOIN dim_date d ON f.date_key = d.date_key
)
SELECT 
    Time_Segment,
    COUNT(*) AS Total_Transactions,
    SUM(transaction_amount) AS Total_Volume,
    AVG(transaction_amount) AS Avg_Transaction_Value,
    MAX(transaction_amount) AS Max_Single_Transaction
FROM WeekdayTimeAnalysis
GROUP BY Time_Segment
ORDER BY Total_Transactions;

-- Day number anaylsis
SELECT 
    DAY(full_date) AS Day_of_Month,
    COUNT(*) AS Transaction_Count,
    AVG(transaction_amount) AS Avg_Value,
    SUM(transaction_amount) AS Total_Volume
FROM fact_transaction f
JOIN dim_date d ON f.date_key = d.date_key
GROUP BY DAY(full_date)
ORDER BY Total_Volume DESC;


-- Monthly Breakdown to show the trend
SELECT 
    FORMAT(full_date, 'yyyy-MM') AS Month_Year,
    COUNT(transaction_id) AS Total_Transactions,
    SUM(transaction_amount) AS Total_Volume
FROM dim_date d
join fact_transaction f ON f.date_key = d.date_key
GROUP BY FORMAT(full_date, 'yyyy-MM')
ORDER BY Month_Year;

SELECT
   COUNT(date_key) AS num_day_transaction
FROM dim_date; -- just 55 day but +1M transaction

-- Range date
SELECT 
    MAX(full_date) AS Max_Transaction_date,
    MIN(full_date) AS Min_Transaction_date
FROM dim_date;
-- 33% of days don't have any transaction

-- Find the gaps between consecutive transaction dates
WITH DateLead AS (
    SELECT 
        full_date,
        LEAD(full_date) OVER (ORDER BY full_date) AS next_date
    FROM (SELECT DISTINCT full_date FROM dim_date) AS DistinctDates
)
SELECT 
    full_date AS Gap_Starts,
    next_date AS Gap_Ends,
    DATEDIFF(day, full_date, next_date) - 1 AS Days_Missing
FROM DateLead
WHERE DATEDIFF(day, full_date, next_date) > 1
ORDER BY Days_Missing DESC;
