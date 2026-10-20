-- Question: Using a window function, compute each card's transaction
-- count in the trailing 24 hours (a velocity check).
--
-- Why it matters: velocity is the single strongest fraud-ring / stolen-card
-- signal in the whole project. Queries 5, 8, and 9 all build on this idea.

SELECT
    t.card_id,
    t.txn_datetime,
    t.amount,
    t.is_fraud,
    (
        SELECT COUNT(*)
        FROM transactions t2
        WHERE t2.card_id = t.card_id
          AND t2.txn_datetime <= t.txn_datetime
          AND t2.txn_datetime > datetime(t.txn_datetime, '-24 hours')
    ) AS txn_count_trailing_24hr
FROM transactions t
WHERE t.card_id = (SELECT card_id FROM transactions GROUP BY card_id ORDER BY COUNT(*) DESC LIMIT 1)
ORDER BY t.txn_datetime
LIMIT 30;
