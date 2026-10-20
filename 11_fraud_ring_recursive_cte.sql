-- Question: Find merchants hit by multiple different cards committing
-- fraud within a short window of each other, a fraud-ring signal.

WITH risky_merchants AS (
    SELECT merchant_id
    FROM transactions
    GROUP BY merchant_id
    HAVING COUNT(*) >= 100
       AND 1.0 * SUM(is_fraud) / COUNT(*) >= 0.1
),
fraud_txns AS (
    SELECT card_id, merchant_id, txn_datetime
    FROM transactions
    WHERE is_fraud = 1
      AND merchant_id IN (SELECT merchant_id FROM risky_merchants)
)
SELECT
    f.merchant_id,
    COUNT(DISTINCT t.card_id) AS distinct_cards_involved
FROM fraud_txns f
JOIN transactions t
  ON t.merchant_id = f.merchant_id
 AND t.txn_datetime BETWEEN f.txn_datetime AND datetime(f.txn_datetime, '+1 hour')
 AND t.card_id != f.card_id
GROUP BY f.merchant_id
HAVING COUNT(DISTINCT t.card_id) >= 3
ORDER BY distinct_cards_involved DESC
LIMIT 20;
