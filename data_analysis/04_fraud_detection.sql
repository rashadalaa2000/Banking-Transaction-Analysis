WITH base AS (
    SELECT 
        f.transaction_id,
        f.customer_id,
        f.transaction_amount,
        f.customer_account_balance,
        f.transaction_time,
        d.full_date,
        d.is_weekend,
        c.customer_location,
        
        DATEPART(HOUR, f.transaction_time) AS txn_hour,

        LAG(f.customer_account_balance) OVER (
            PARTITION BY f.customer_id 
            ORDER BY f.date_key, f.transaction_time
        ) AS prev_balance

    FROM fintech.dbo.fact_transaction f
    LEFT JOIN fintech.dbo.dim_date d 
        ON f.date_key = d.date_key
    LEFT JOIN fintech.dbo.dim_customers c 
        ON f.customer_id = c.customer_id
),

-- Daily behavior
daily_stats AS (
    SELECT 
        customer_id,
        CAST(full_date AS DATE) AS transaction_day,
        COUNT(*) AS daily_txn_count,
        SUM(transaction_amount) AS daily_total
    FROM base
    GROUP BY customer_id, CAST(full_date AS DATE)
),

-- Customer baseline
customer_avg AS (
    SELECT 
        customer_id,
        AVG(daily_total) AS avg_daily_total,
        AVG(daily_txn_count) AS avg_daily_count
    FROM daily_stats
    GROUP BY customer_id
)

SELECT 
    b.*,
    ds.daily_txn_count,
    ds.daily_total,
    ca.avg_daily_total,
    ca.avg_daily_count,

    -- Signals
    CASE WHEN b.prev_balance IS NOT NULL 
              AND (b.prev_balance - b.customer_account_balance) > 20000 
         THEN 1 ELSE 0 END AS balance_drop_flag,

    CASE WHEN b.txn_hour BETWEEN 1 AND 5 
         THEN 1 ELSE 0 END AS night_flag,

    CASE WHEN ds.daily_total > ca.avg_daily_total * 3 
         THEN 1 ELSE 0 END AS spike_flag,

    -- Risk Score
    (
        CASE WHEN ds.daily_total > ca.avg_daily_total * 3 THEN 2 ELSE 0 END +
        CASE WHEN ds.daily_txn_count > ca.avg_daily_count * 3 THEN 2 ELSE 0 END +
        CASE WHEN b.txn_hour BETWEEN 1 AND 5 THEN 1 ELSE 0 END +
        CASE WHEN (b.prev_balance - b.customer_account_balance) > 20000 THEN 2 ELSE 0 END
    ) AS risk_score,

    CASE 
        WHEN (
            CASE WHEN ds.daily_total > ca.avg_daily_total * 3 THEN 2 ELSE 0 END +
            CASE WHEN ds.daily_txn_count > ca.avg_daily_count * 3 THEN 2 ELSE 0 END +
            CASE WHEN b.txn_hour BETWEEN 1 AND 5 THEN 1 ELSE 0 END +
            CASE WHEN (b.prev_balance - b.customer_account_balance) > 20000 THEN 2 ELSE 0 END
        ) >= 5 THEN 'High Risk '

        WHEN (
            CASE WHEN ds.daily_total > ca.avg_daily_total * 3 THEN 2 ELSE 0 END +
            CASE WHEN ds.daily_txn_count > ca.avg_daily_count * 3 THEN 2 ELSE 0 END +
            CASE WHEN b.txn_hour BETWEEN 1 AND 5 THEN 1 ELSE 0 END +
            CASE WHEN (b.prev_balance - b.customer_account_balance) > 20000 THEN 2 ELSE 0 END
        ) >= 3 THEN 'Medium Risk'

        ELSE 'Low Risk'
    END AS risk_level

FROM base b
LEFT JOIN daily_stats ds 
    ON b.customer_id = ds.customer_id 
    AND CAST(b.full_date AS DATE) = ds.transaction_day

LEFT JOIN customer_avg ca 
    ON b.customer_id = ca.customer_id

WHERE 
    (
        CASE WHEN ds.daily_total > ca.avg_daily_total * 3 THEN 2 ELSE 0 END +
        CASE WHEN ds.daily_txn_count > ca.avg_daily_count * 3 THEN 2 ELSE 0 END +
        CASE WHEN b.txn_hour BETWEEN 1 AND 5 THEN 1 ELSE 0 END +
        CASE WHEN (b.prev_balance - b.customer_account_balance) > 20000 THEN 2 ELSE 0 END
    ) >= 3

ORDER BY risk_score DESC;
