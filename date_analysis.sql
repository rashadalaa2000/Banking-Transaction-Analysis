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
    WHERE d.is_weekend = 0 
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
    DAY(transaction_date) AS Day_of_Month,
    COUNT(*) AS Transaction_Count,
    AVG(transaction_amount) AS Avg_Value,
    SUM(transaction_amount) AS Total_Volume
FROM fact_transaction f
JOIN dim_date d ON f.date_key = d.date_key
WHERE d.is_weekend = 0
GROUP BY DAY(transaction_date)
ORDER BY Total_Volume DESC;


-- Compare the start of the 55 days vs the end
WITH TimedData AS (
    SELECT 
        transaction_date,
        SUM(transaction_amount) AS Daily_Sum,
        COUNT(*) AS Daily_Count
    FROM fact_transaction
    GROUP BY transaction_date
)
SELECT * FROM (
    (SELECT TOP 2 'Start of Period' AS Period, * FROM TimedData ORDER BY transaction_date ASC)
    UNION ALL
    (SELECT TOP 2 'End of Period' AS Period, * FROM TimedData ORDER BY transaction_date DESC)
) AS Comparison;

-- Monthly Breakdown to show the trend
SELECT 
    FORMAT(transaction_date, 'yyyy-MM') AS Month_Year,
    COUNT(transaction_id) AS Total_Transactions,
    SUM(transaction_amount) AS Total_Volume
FROM fact_transaction
GROUP BY FORMAT(transaction_date, 'yyyy-MM')
ORDER BY Month_Year;

SELECT
   COUNT(date_key) AS num_day_transaction
FROM dim_date; -- just 55 day but +1M transaction

-- Range date
SELECT 
    MAX(transaction_date) AS Max_Transaction_date,
    MIN(transaction_date) AS Min_Transaction_date
FROM fact_transaction;
-- 33% of days don't have any transaction

-- Find the gaps between consecutive transaction dates
WITH DateLead AS (
    SELECT 
        transaction_date,
        LEAD(transaction_date) OVER (ORDER BY transaction_date) AS next_date
    FROM (SELECT DISTINCT transaction_date FROM fact_transaction) AS DistinctDates
)
SELECT 
    transaction_date AS Gap_Starts,
    next_date AS Gap_Ends,
    DATEDIFF(day, transaction_date, next_date) - 1 AS Days_Missing
FROM DateLead
WHERE DATEDIFF(day, transaction_date, next_date) > 1
ORDER BY Days_Missing DESC;


/* Transaction gaps caused by scheduled bank holidays in India or (Data Sampling),
 i think it Data Sampling beacuse 33% not make sense to be holiday 
& The weekend recorded the highest total transaction value.
& if i take Consecutive data this will be biased sampling (Convenience Sampling)
*/

/* 
BUSINESS INSIGHTS & ANALYTICS SUMMARY

1. AFTER-HOURS "WHALE" ACTIVITY:
70% of the Top 10 largest transactions occur outside standard banking hours (Post-6 PM), 
contributing over 6.5M INR. This indicates a heavy reliance on the system for 
Merchant settlements and VIP retail spending during off-peak hours.

2. THE THURSDAY B2B CEILING: 
Thursday recorded the absolute highest single transaction of 1,560,035 INR at 1:27 PM. 
This is the only "Pure Corporate" peak in the Top 5, marking Thursday as the 
primary day for institutional liquidity movements.

3. WEEKEND VALUE PREMIUM: 
Despite lower "Max" values, Saturdays & Sundays maintain the highest Average 
Transaction Value (~1,660 INR). This proves that weekend retail traffic is 
of "higher quality" compared to the high-volume/low-average weekday churn.

4. THE 8:00 PM CAPACITY PEAK: 
System load reaches its absolute maximum at 20:00 (8:00 PM), driven by a 
convergence of high-value VIP transfers and late-evening retail activity.


5. Peak Operational Hours: 
The highest system traffic occurs between 5 PM and 9 PM, 
with the absolute peak at 8 PM (97,053 transactions).

6. Strategic Sampling Reliability:
The dataset utilizes a 15% annual sampling rate 
with non-consecutive intervals (Gaps) to eliminate Seasonal Bias. 
This methodology ensures that the insights are representative of the entire fiscal year's behavior,
rather than being skewed by a single continuous time period.

7. "Midnight" Merchant Liquidity:
A significant cluster of high-value transactions (e.g., 536K INR) occurs as late as 11:30 PM. 
This highlights a specific segment of "Night-Owl Merchants" 
who perform digital settlements after closing their physical stores, 
emphasizing the need for 24/7 system stability.

8. High-Velocity Active Days:
While 33% of the calendar shows no activity (due to the sampling design), 
the Active Days demonstrate extreme density, processing over 1 million transactions in just 55 days. 
This proves the system's high-concurrency handling capability during peak periods.

================================================================================
*/