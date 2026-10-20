-- Question: Which cards had a transaction count in a 1-hour window
-- that is unusually high compared to that card's own typical activity?
--
-- Why it matters: a per-card baseline catches velocity spikes that a flat
-- threshold would miss for naturally high-volume cards, and miss for
-- naturally low-volume cards.

WITH hourly_counts AS (
    SELECT
        t.card_id,
        t.txn_datetime,
        (
            SELECT COUNT(*)
            FROM transactions t2
            WHERE t2.card_id = t.card_id
              AND t2.txn_datetime <= t.txn_datetime
              AND t2.txn_datetime > datetime(t.txn_datetime, '-1 hours')
        ) AS txn_count_trailing_1hr
    FROM transactions t
    WHERE t.card_id = (SELECT card_id FROM transactions GROUP BY card_id ORDER BY COUNT(*) DESC LIMIT 1)
)
SELECT *
FROM hourly_counts
ORDER BY txn_count_trailing_1hr DESC
LIMIT 20;
