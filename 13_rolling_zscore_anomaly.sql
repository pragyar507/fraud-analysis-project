-- Question: Using a rolling mean and approximate rolling standard
-- deviation, flag transactions more than 3 standard deviations above a
-- card's own recent trailing average.

WITH rolling_mean AS (
    SELECT
        rowid AS txn_rowid,
        card_id,
        txn_datetime,
        amount,
        is_fraud,
        AVG(amount) OVER (
            PARTITION BY card_id
            ORDER BY txn_datetime
            ROWS BETWEEN 30 PRECEDING AND 1 PRECEDING
        ) AS rolling_avg
    FROM transactions
    WHERE is_refund_or_reversal = 0
      AND card_id = (SELECT card_id FROM transactions GROUP BY card_id ORDER BY COUNT(*) DESC LIMIT 1)
),
rolling_var AS (
    SELECT
        rm.txn_rowid,
        rm.card_id,
        rm.txn_datetime,
        rm.amount,
        rm.is_fraud,
        rm.rolling_avg,
        (
            SELECT AVG((t2.amount - rm.rolling_avg) * (t2.amount - rm.rolling_avg))
            FROM transactions t2
            WHERE t2.card_id = rm.card_id
              AND t2.txn_datetime < rm.txn_datetime
            ORDER BY t2.txn_datetime DESC
            LIMIT 30
        ) AS rolling_variance
    FROM rolling_mean rm
    WHERE rm.rolling_avg IS NOT NULL
)
SELECT
    card_id,
    txn_datetime,
    amount,
    is_fraud,
    ROUND(rolling_avg, 2) AS rolling_avg_30txn,
    ROUND(SQRT(rolling_variance), 2) AS rolling_stddev_30txn,
    ROUND((amount - rolling_avg) / NULLIF(SQRT(rolling_variance), 0), 2) AS z_score
FROM rolling_var
WHERE rolling_variance IS NOT NULL
  AND amount > rolling_avg + 3 * SQRT(rolling_variance)
ORDER BY z_score DESC
LIMIT 20;
