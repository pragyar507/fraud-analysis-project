-- Question: Find transactions where the same card was used in two
-- different states within an implausibly short time window.

WITH ordered_txns AS (
    SELECT
        card_id,
        amount,
        merchant_state,
        txn_datetime,
        LAG(merchant_state) OVER (PARTITION BY card_id ORDER BY txn_datetime) AS prev_state,
        LAG(txn_datetime) OVER (PARTITION BY card_id ORDER BY txn_datetime) AS prev_time
    FROM transactions
    WHERE merchant_state != 'ONLINE'
)
SELECT
    card_id,
    prev_state,
    merchant_state,
    prev_time,
    txn_datetime,
    ROUND((julianday(txn_datetime) - julianday(prev_time)) * 24, 2) AS hours_between
FROM ordered_txns
WHERE merchant_state != prev_state
  AND (julianday(txn_datetime) - julianday(prev_time)) * 24 < 2
ORDER BY hours_between ASC
LIMIT 20;
