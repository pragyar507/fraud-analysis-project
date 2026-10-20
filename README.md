# Credit Card Fraud & Transaction Risk Analytics for Banking


This project analyzes 24.4 million credit card transactions to find patterns that predict fraud, patterns a typical rules-based system (one that just flags transactions over a dollar amount) would miss. Two of those patterns, how risky a merchant historically is, and whether a transaction is unusually large for that specific card, were added to a fraud-detection model. That alone raised the model's fraud recall from 54% to 64% and its ROC-AUC from 0.748 to 0.826, proving these SQL-derived signals genuinely improve detection rather than just producing interesting tables. The strongest individual signal, a dynamic spending threshold unique to each card, flagged only confirmed fraud in its top 20 results, with zero false positives.

## Data

The [Kaggle IBM TabFormer credit card transactions
dataset](https://www.kaggle.com/datasets/ealtman2019/credit-card-transactions):
24,386,900 transactions across roughly 2,000 synthetic cards, spanning
1991-2020. The raw file (`credit_card_transactions-ibm_v2.csv`, ~2.3GB)
is not included; see **How to run**.

## Approach

- Cleaned the raw CSV: parsed `Amount` from a currency string to a float,
  combined date/time fields into a single datetime, built a `card_id`
  from the user and card index, converted `is_fraud` to 0/1, and added
  `is_refund_or_reversal` and `is_online_channel` flags.
- Loaded the cleaned data into a local SQLite database and wrote 13 SQL
  queries (`sql/`), each answering one specific fraud question: overall
  rate, amount comparison, time-of-day, card velocity (1hr/24hr),
  merchant risk ranking, geographically impossible transactions, a
  composite risk score, risk deciles, card-testing patterns, fraud-ring
  detection, a dynamic per-card percentile threshold, and rolling
  z-score anomaly detection.
- Built two logistic regression models on a stratified sample: a
  baseline using only amount, amount deviation, hour, and card
  transaction count, and an enhanced model adding the merchant-risk and
  per-card-threshold features surfaced by the SQL analysis, to test
  whether those findings actually improve detection rather than just
  producing interesting tables.

### How the model improved

| Model | Features | Recall | ROC-AUC |
|---|---|---|---|
| Baseline | amount, amount deviation, hour, card txn count | 0.54 | 0.748 |
| Enhanced | + merchant fraud rate, + above-p95 flag | 0.64 | 0.826 |

## Findings

- Overall fraud rate: 0.122% (29,757 of 24,386,900 transactions)
- Fraud concentrates by merchant category: cruise lines (50%), music
  stores (25.6%), and computer stores (9.4%) have the highest rates
- One merchant had a 100% fraud rate across 148 transactions, a likely
  compromised payment system rather than a genuinely risky category
- The riskiest 10% of cards account for over a third of all fraud; the
  safest 50% of cards had zero fraud transactions
- Fraud rate by hour has two peaks (roughly 3-5am and 10am-1pm), not a
  single overnight spike
- A merchant with 43 distinct cards hit by fraud within an hour of each
  other is a strong fraud-ring signal, found via a non-recursive
  bounded join rather than an unbounded recursive CTE, which blew up on
  the full 24.4M-row table

## Business recommendations

1. Add merchant-category risk scoring to the existing rules engine; it's
   a cheap, high-signal addition ahead of any model rollout.
2. Add a per-card dynamic spending threshold (95th percentile of that
   card's own history) instead of a flat dollar cutoff.
3. Prioritize manual review capacity toward the riskiest 10% of cards by
   historical fraud rate.
4. Flag the merchant-ring pattern (several different cards hit at the
   same merchant within a short window) for escalation separate from
   single-card fraud alerts.
5. Treat merchants with suspiciously high fraud concentration and low
   transaction volume (like the 100%-fraud-rate merchant) as a possible
   compromised payment system, not just a risky category.

## Limitations

- The dataset is synthetic (IBM TabFormer), so fraud patterns may not
  fully match real-world behavior.
- The rolling z-score anomaly check (query 13) was run on one
  high-activity card rather than the full dataset; the full correlated
  subquery was computationally infeasible on this hardware.
- The recursive fraud-ring CTE as originally designed caused a
  combinatorial explosion on the full table and had to be replaced with
  a bounded, non-recursive join.
- Models were trained on a 1% random sample for tractability, not the
  full 24.4M rows.

## Repo structure

```
fraud-analytics-project/
├── sql/                       13 queries, each documented with what
│                               it answers and why it matters
├── Notebooks/
│   └── fraud_analysis.ipynb   runs every query, EDA, feature
│                               engineering, modeling, business
│                               translation
├── requirements.txt
└── README.md
```

## How to run

1. Download the dataset from
   [Kaggle](https://www.kaggle.com/datasets/ealtman2019/credit-card-transactions)
   and place `credit_card_transactions-ibm_v2.csv` in the `Notebooks/`
   folder (not included here due to file size).
2. `pip install -r requirements.txt`
3. Open `Notebooks/fraud_analysis.ipynb` and run the cells in order. It
   cleans the raw data, loads it into a local SQLite database, and runs
   every query in `sql/` directly against it.

## Tools

Python, pandas, SQLite, scikit-learn, matplotlib, Jupyter Notebook.
