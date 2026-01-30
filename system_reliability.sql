-- Number of failures
SELECT 
    CASE 
        WHEN transaction_amount = 0 THEN 'Failed'
        ELSE 'Successful'
    END AS transaction_health,
    COUNT(*) AS total_count,
    CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS DECIMAL(10,2)) AS percentage
FROM fact_transaction
GROUP BY 
    CASE 
        WHEN transaction_amount = 0 THEN 'Failed'
        ELSE 'Successful'
    END;
 -- system very stable  

-- Business Hours failures VS After-Hours
SELECT 
    CASE 
        WHEN transaction_time BETWEEN '09:00:00' AND '18:00:00' THEN 'Business Hours'
        ELSE 'After-Hours'
    END AS time_segment,
    COUNT(CASE WHEN transaction_amount = 0 THEN 1 END) AS zero_amt_count,
    COUNT(*) AS total_tx,
    CAST(COUNT(CASE WHEN transaction_amount = 0 THEN 1 END) * 100.0 / COUNT(*) AS DECIMAL(10,2)) AS failure_rate
FROM fact_transaction
GROUP BY 
    CASE 
        WHEN transaction_time BETWEEN '09:00:00' AND '18:00:00' THEN 'Business Hours'
        ELSE 'After-Hours'
    END;
-- Almost equal

-- Unlucky customer
SELECT 
    f.customer_id,
    COUNT(*) AS failed_count,
    MIN(f.transaction_date) AS first_fail,
    MAX(f.transaction_date) AS last_fail
FROM fact_transaction f
WHERE f.transaction_amount = 0
GROUP BY f.customer_id
HAVING COUNT(*) > 1;
-- NO fail 2 time for 1 customer

SELECT 
    transaction_date,
    DATEPART(HOUR, transaction_time) AS Hour_of_Day,
    COUNT(*) AS Failures_In_Hour,
    SUM(COUNT(*)) OVER(PARTITION BY transaction_date) AS Total_Daily_Failures
FROM fact_transaction
WHERE transaction_amount = 0
GROUP BY transaction_date, DATEPART(HOUR, transaction_time)
HAVING COUNT(*) > 5 
ORDER BY Failures_In_Hour DESC;
-- may be System update time



/* 
System_Reliability Insight

1. SYSTEM RELIABILITY: 
The system is highly stable with a 99.92% success rate. 
Only 0.08% (835 transactions) failed to register an amount.

2. NO REPEAT FAILURES: 
Zero customers experienced more than one failure. 
This proves failures are random/temporary and not due to specific account issues.

3. PEAK LOAD BOTTLENECK: 
A micro-outage occurred on Sept 1st at 11:00 AM (21 failures). 
This matches the monthly payroll peak, indicating a high-traffic bottleneck.

4. MAINTENANCE WINDOWS: 
Small failure clusters at 4:00 AM (e.g., Aug 12th & 20th) 
suggest routine system maintenance or backups during low-activity hours.
*/
