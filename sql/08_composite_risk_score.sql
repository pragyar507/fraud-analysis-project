-- Question: Combine per-card spending deviation and merchant risk
-- into a single composite risk score per transaction.

WITH card_avg AS (
    SELECT card_id, AVG(amount) AS card_avg_amount
    FROM transactions
    WHERE amount > 0
    GROUP BY card_id
),
merchant_risk AS (
    SELECT merchant_id, 1.0 * SUM(is_fraud) / COUNT(*) AS merchant_fraud_rate
    FROM transactions
    GROUP BY merchant_id
    HAVING COUNT(*) >= 100
)
SELECT
    t.card_id,
    t.txn_datetime,
    t.amount,
    t.is_fraud,
    ROUND(ABS(t.amount - ca.card_avg_amount), 2) AS amount_deviation,
    ROUND(COALESCE(mr.merchant_fraud_rate, 0), 4) AS merchant_fraud_rate,
    ROUND(
        0.5 * (ABS(t.amount - ca.card_avg_amount) / NULLIF(ca.card_avg_amount, 0))
        + 0.5 * COALESCE(mr.merchant_fraud_rate, 0) * 10,
        4
    ) AS composite_risk_score
FROM transactions t
JOIN card_avg ca ON ca.card_id = t.card_id
LEFT JOIN merchant_risk mr ON mr.merchant_id = t.merchant_id
ORDER BY composite_risk_score DESC
LIMIT 20;
