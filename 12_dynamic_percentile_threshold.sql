-- Question: Flag transactions that exceed each card's own 95th-percentile
-- spending amount, a dynamic per-card threshold.

WITH ranked AS (
    SELECT
        card_id,
        amount,
        is_fraud,
        txn_datetime,
        PERCENT_RANK() OVER (PARTITION BY card_id ORDER BY amount) AS pct_rank
    FROM transactions
    WHERE amount > 0
),
card_p95 AS (
    SELECT card_id, MIN(amount) AS p95_amount
    FROM ranked
    WHERE pct_rank >= 0.95
    GROUP BY card_id
)
SELECT
    t.card_id,
    t.txn_datetime,
    t.amount,
    t.is_fraud,
    cp.p95_amount
FROM transactions t
JOIN card_p95 cp ON cp.card_id = t.card_id
WHERE t.amount > cp.p95_amount
ORDER BY t.is_fraud DESC, t.amount DESC
LIMIT 20;
