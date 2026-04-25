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


SELECT
    DATEPART(HOUR, transaction_time) AS Hour_of_Day,
    COUNT(*) AS Failures_In_Hour
FROM fact_transaction
WHERE transaction_amount = 0
GROUP BY DATEPART(HOUR, transaction_time)
ORDER BY Failures_In_Hour DESC;
-- for System update time
