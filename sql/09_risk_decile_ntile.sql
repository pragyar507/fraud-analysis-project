-- Question: Bucket cards into risk deciles by their individual fraud rate.

WITH card_score AS (
    SELECT
        card_id,
        COUNT(*) AS txn_count,
        SUM(is_fraud) AS fraud_count,
        1.0 * SUM(is_fraud) / COUNT(*) AS fraud_rate
    FROM transactions
    GROUP BY card_id
),
deciled AS (
    SELECT *,
        NTILE(10) OVER (ORDER BY fraud_rate DESC) AS risk_decile
    FROM card_score
)
SELECT
    risk_decile,
    COUNT(*) AS n_cards,
    SUM(fraud_count) AS total_fraud_in_decile,
    ROUND(AVG(fraud_rate), 5) AS avg_fraud_rate
FROM deciled
GROUP BY risk_decile
ORDER BY risk_decile;
