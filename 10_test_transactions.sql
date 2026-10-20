-- Question: Find a small test charge immediately followed by a large
-- charge on the same card, a classic card-testing pattern.

WITH ordered AS (
    SELECT
        card_id,
        amount,
        txn_datetime,
        is_fraud,
        LEAD(amount) OVER (PARTITION BY card_id ORDER BY txn_datetime) AS next_amount,
        LEAD(txn_datetime) OVER (PARTITION BY card_id ORDER BY txn_datetime) AS next_time
    FROM transactions
    WHERE amount > 0
)
SELECT
    card_id,
    amount AS test_charge_amount,
    txn_datetime AS test_charge_time,
    next_amount AS followup_amount,
    next_time AS followup_time,
    ROUND((julianday(next_time) - julianday(txn_datetime)) * 24 * 60, 1) AS minutes_between
FROM ordered
WHERE amount <= 2.00
  AND next_amount >= 100.00
  AND (julianday(next_time) - julianday(txn_datetime)) * 24 <= 1
ORDER BY minutes_between ASC
LIMIT 20;
