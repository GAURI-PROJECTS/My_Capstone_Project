# Mutual Fund Data Warehouse — Data Dictionary

> **Database:** `mutual_fund_dw.db` (SQLite 3.45)  
> **Schema type:** Star schema — 2 dimensions, 9 fact tables  
> **Data coverage:** January 2022 – May 2026  
> **Total rows loaded:** 87,573 across all tables  

---

## Table of Contents

1. [Schema Overview](#schema-overview)
2. [Dimension Tables](#dimension-tables)
   - [dim_fund](#dim_fund)
   - [dim_date](#dim_date)
3. [Core Fact Tables](#core-fact-tables)
   - [fact_nav](#fact_nav)
   - [fact_transactions](#fact_transactions)
   - [fact_performance](#fact_performance)
   - [fact_aum](#fact_aum)
4. [Extended Fact Tables](#extended-fact-tables)
   - [fact_sip_inflows](#fact_sip_inflows)
   - [fact_category_inflows](#fact_category_inflows)
   - [fact_folio_count](#fact_folio_count)
   - [fact_portfolio_holdings](#fact_portfolio_holdings)
   - [fact_benchmark_indices](#fact_benchmark_indices)
5. [Key Relationships](#key-relationships)
6. [Controlled Vocabularies](#controlled-vocabularies)
7. [Source File Reference](#source-file-reference)

---

## Schema Overview

```
                        ┌─────────────┐
                        │  dim_date   │
                        │  (1,340)    │
                        └──────┬──────┘
                               │ date_id
          ┌────────────────────┼────────────────────┐
          │                    │                    │
    ┌─────▼──────┐      ┌──────▼──────┐    ┌───────▼──────┐
    │  fact_nav  │      │  fact_aum   │    │ fact_sip_    │
    │  (46,000)  │      │    (90)     │    │ inflows (48) │
    └─────┬──────┘      └─────────────┘    └──────────────┘
          │ amfi_code
    ┌─────▼──────┐      ┌─────────────┐    ┌──────────────┐
    │  dim_fund  ├──────► fact_perf   │    │ fact_cat_    │
    │    (40)    │      │    (40)     │    │ inflows(144) │
    └─────┬──────┘      └─────────────┘    └──────────────┘
          │
    ┌─────▼──────┐      ┌─────────────┐    ┌──────────────┐
    │ fact_txn   │      │ fact_port_  │    │ fact_folio_  │
    │ (32,778)   │      │ holdings    │    │ count  (21)  │
    └────────────┘      │   (322)     │    └──────────────┘
                        └─────────────┘
```

Every fact table joins to `dim_date` via `date_id` and, where applicable, to `dim_fund` via `amfi_code`. All joins are a single hop.

---

## Dimension Tables

### dim_fund

**Description:** Master reference for all mutual fund schemes. One row per AMFI-registered scheme. Slowly-changing dimension — attributes like `expense_ratio_pct` may change over time but the table holds the latest snapshot.

**Source:** `cleaned_01_fund_master.csv`  
**Row count:** 40  
**Primary key:** `amfi_code`

| Column | Data Type | Nullable | Business Definition | Example Values |
|--------|-----------|----------|---------------------|----------------|
| `amfi_code` | INTEGER | NOT NULL | Unique scheme identifier assigned by the Association of Mutual Funds in India (AMFI). Used as the universal join key across all fund-level fact tables. | `100033`, `118989` |
| `fund_house` | TEXT | NOT NULL | Name of the Asset Management Company (AMC) that manages the scheme. | `HDFC Mutual Fund`, `SBI Mutual Fund`, `Axis Mutual Fund` |
| `scheme_name` | TEXT | NOT NULL | Full official name of the mutual fund scheme as registered with SEBI. | `HDFC Large Cap Fund - Growth` |
| `category` | TEXT | NULL | Broad SEBI-mandated asset class of the scheme. | `Equity`, `Debt` |
| `sub_category` | TEXT | NULL | Granular classification within the category as per SEBI's October 2017 categorisation circular. | `Large Cap`, `Mid Cap`, `Small Cap`, `Flexi Cap`, `Short Duration`, `Liquid`, `Index`, `Index/ETF` |
| `plan` | TEXT | NULL | Distribution plan of the scheme. Direct plans have no distributor commission; Regular plans include it in the expense ratio. | `Direct`, `Regular` |
| `launch_date` | DATE | NULL | Date the scheme was open for public subscription. Format: `YYYY-MM-DD`. | `2013-01-01` |
| `benchmark` | TEXT | NULL | Market index against which the fund's performance is officially measured. Used in alpha/beta calculations. | `Nifty 50 TRI`, `BSE Sensex TRI`, `CRISIL Short Term Bond Index` |
| `expense_ratio_pct` | REAL | NULL | Annual fee charged by the AMC as a percentage of daily AUM. Deducted from NAV before publication. SEBI caps: Equity ≤ 2.25%, Debt ≤ 2.00%. | `0.55` – `1.64` |
| `exit_load_pct` | REAL | NULL | Penalty charged on redemption before a defined holding period, expressed as a percentage of redemption value. `0.0` means no exit load. | `0.0`, `1.0` |
| `min_sip_amount` | INTEGER | NULL | Minimum amount in ₹ required to start a Systematic Investment Plan in this scheme. | `500`, `1000` |
| `min_lumpsum_amount` | INTEGER | NULL | Minimum one-time investment amount in ₹ accepted by this scheme. | `1000`, `5000` |
| `fund_manager` | TEXT | NULL | Name of the lead portfolio manager responsible for investment decisions. | `Prashant Jain`, `Neelesh Surana` |
| `risk_category` | TEXT | NULL | SEBI-mandated risk-o-meter label printed on all scheme documents. Based on portfolio composition. | `Low`, `Moderate`, `Moderately High`, `High`, `Very High` |
| `sebi_category_code` | TEXT | NULL | Internal code mapping to SEBI's scheme classification framework. Prefix indicates asset class: `EC` = Equity, `DC` = Debt, `EI` = Equity Index. | `EC01`, `EC02`, `DC01`, `EI01` |

---

### dim_date

**Description:** Calendar dimension spanning every date present in any fact table. Enriched with fiscal and calendar attributes to avoid repeated date calculations in queries. One row per unique calendar date.

**Source:** Derived — generated programmatically from all date columns across all source CSVs.  
**Row count:** 1,340  
**Primary key:** `date_id`  
**Date coverage:** 2 January 2022 – 29 May 2026

| Column | Data Type | Nullable | Business Definition | Example Values |
|--------|-----------|----------|---------------------|----------------|
| `date_id` | TEXT | NOT NULL | ISO 8601 calendar date string (`YYYY-MM-DD`). Natural primary key and foreign key target for all fact tables. String format chosen for SQLite compatibility and human readability. | `2024-03-31`, `2025-01-01` |
| `year` | INTEGER | NOT NULL | Calendar year extracted from `date_id`. | `2022`, `2023`, `2024`, `2025`, `2026` |
| `quarter` | INTEGER | NOT NULL | Calendar quarter (1–4). Q1 = Jan–Mar, Q2 = Apr–Jun, Q3 = Jul–Sep, Q4 = Oct–Dec. | `1`, `2`, `3`, `4` |
| `month` | INTEGER | NOT NULL | Calendar month number (1–12). | `1` (January) – `12` (December) |
| `month_name` | TEXT | NOT NULL | Full English name of the month. Useful for display labels without a CASE expression. | `January`, `February`, … `December` |
| `week` | INTEGER | NOT NULL | ISO 8601 week number (1–53). Week 1 is the week containing the first Thursday of the year. | `1` – `53` |
| `day` | INTEGER | NOT NULL | Day of the month (1–31). | `1` – `31` |
| `day_name` | TEXT | NOT NULL | Full English name of the day of week. | `Monday`, `Tuesday`, … `Sunday` |
| `is_month_end` | INTEGER | NOT NULL | Flag: `1` if this date is the last day of its calendar month, `0` otherwise. Used to filter month-end NAV and AUM snapshots. Default: `0`. | `0`, `1` |

---

## Core Fact Tables

### fact_nav

**Description:** Daily Net Asset Value for each mutual fund scheme. NAV is the per-unit market value of the fund, calculated after market close on every trading day by dividing total AUM by outstanding units. This is the primary pricing table.

**Source:** `Cleaned_02_nav_history.csv`  
**Row count:** 46,000  
**Primary key:** `nav_id` (surrogate)  
**Natural key:** `(amfi_code, date_id)` — UNIQUE constraint enforced  
**Date range:** 3 January 2022 – 29 May 2026

| Column | Data Type | Nullable | Business Definition | Example Values |
|--------|-----------|----------|---------------------|----------------|
| `nav_id` | INTEGER | NOT NULL | Auto-incrementing surrogate primary key. No business meaning. | `1`, `2`, … |
| `amfi_code` | INTEGER | NOT NULL | Foreign key → `dim_fund.amfi_code`. Identifies the scheme whose NAV is recorded. | `100033` |
| `date_id` | TEXT | NOT NULL | Foreign key → `dim_date.date_id`. The trading date for this NAV. NAV is not published on weekends or NSE/BSE holidays. | `2024-01-15` |
| `nav` | REAL | NOT NULL | Closing NAV in Indian Rupees (₹) per unit. Calculated as `(Market Value of Assets − Liabilities) / Outstanding Units`. Range in dataset: ₹26.14 – ₹4,268.55. Average: ₹269.57. | `245.6700`, `1832.4500` |

---

### fact_transactions

**Description:** Individual investor transaction records capturing every purchase, redemption, and SIP instalment. Each row is one financial event by one investor in one fund on one date. Contains investor demographic attributes at the time of transaction.

**Source:** `cleaned_08_investor_transactions.csv`  
**Row count:** 32,778  
**Primary key:** `txn_id` (surrogate)  
**Date range:** 1 January 2024 – 30 May 2025

| Column | Data Type | Nullable | Business Definition | Example Values |
|--------|-----------|----------|---------------------|----------------|
| `txn_id` | INTEGER | NOT NULL | Auto-incrementing surrogate primary key. | `1`, `2`, … |
| `investor_id` | TEXT | NOT NULL | Anonymised investor identifier. Not a FK — investor dimension not modelled separately. Consistent within the dataset; one investor may have many transactions. | `INV_00001` |
| `amfi_code` | INTEGER | NOT NULL | Foreign key → `dim_fund.amfi_code`. The scheme in which the transaction was executed. | `100033` |
| `date_id` | TEXT | NOT NULL | Foreign key → `dim_date.date_id`. Date the transaction was processed (T-day). | `2024-06-10` |
| `transaction_type` | TEXT | NOT NULL | Type of investor action. `SIP` = scheduled instalment; `Lumpsum` = one-time purchase; `Redemption` = withdrawal of units. | `SIP`, `Lumpsum`, `Redemption` |
| `amount_inr` | REAL | NOT NULL | Transaction value in Indian Rupees (₹). For purchases: amount invested. For redemptions: amount withdrawn. Range: ₹400 – ₹597,498. Average: ₹107,437. | `5000.00`, `50000.00` |
| `state` | TEXT | NULL | Indian state of the investor's registered address. | `Maharashtra`, `Delhi`, `Gujarat` |
| `city` | TEXT | NULL | City of the investor's registered address. | `Mumbai`, `Pune`, `Bengaluru` |
| `city_tier` | TEXT | NULL | AMFI's investor location classification. `T30` = Top 30 cities (historically 77% of AUM); `B30` = Beyond Top 30 (remaining cities, SEBI focus for penetration). | `T30`, `B30` |
| `age_group` | TEXT | NULL | Investor's age bracket at time of transaction. Derived from KYC date of birth. | `18-25`, `26-35`, `36-45`, `46-55`, `56+` |
| `gender` | TEXT | NULL | Investor's gender as per KYC records. | `Male`, `Female` |
| `annual_income_lakh` | REAL | NULL | Investor's self-declared annual income in ₹ Lakhs (1 Lakh = ₹100,000), as recorded in KYC documents. | `5.5`, `12.0`, `25.0` |
| `payment_mode` | TEXT | NULL | Payment method used for the transaction. Relevant for purchase transactions. | `UPI`, `Net Banking`, `Mandate`, `Cheque` |
| `kyc_status` | TEXT | NULL | KYC (Know Your Customer) verification status of the investor at time of transaction. SEBI mandates KYC completion before investment. | `Verified`, `Pending` |

---

### fact_performance

**Description:** Point-in-time risk-return metrics snapshot for each fund. Covers trailing returns, risk-adjusted performance ratios, and portfolio statistics. One row per fund (latest available snapshot).

**Source:** `cleaned_07_scheme_performance.csv`  
**Row count:** 40  
**Primary key:** `perf_id` (surrogate)  
**Grain:** One snapshot per fund (extend with `date_id` for historical tracking)

| Column | Data Type | Nullable | Business Definition | Example Values |
|--------|-----------|----------|---------------------|----------------|
| `perf_id` | INTEGER | NOT NULL | Auto-incrementing surrogate primary key. | `1`, `2`, … |
| `amfi_code` | INTEGER | NOT NULL | Foreign key → `dim_fund.amfi_code`. | `100033` |
| `return_1yr_pct` | REAL | NULL | Absolute point-to-point return over the trailing 1-year period, expressed as a percentage. `(NAV_today − NAV_1yr_ago) / NAV_1yr_ago × 100`. | `18.5`, `−3.2` |
| `return_3yr_pct` | REAL | NULL | CAGR (Compound Annual Growth Rate) over the trailing 3-year period, in %. CAGR = `(NAV_today / NAV_3yr_ago)^(1/3) − 1`. | `12.4`, `8.7` |
| `return_5yr_pct` | REAL | NULL | CAGR over the trailing 5-year period, in %. | `15.2`, `10.1` |
| `benchmark_3yr_pct` | REAL | NULL | 3-year CAGR of the fund's designated benchmark index over the same period. Used to compute `alpha`. | `11.8`, `7.9` |
| `alpha` | REAL | NULL | Jensen's Alpha: excess return generated by the fund manager above what the benchmark returned, adjusted for market risk. `Alpha = Fund Return − [Risk-Free Rate + Beta × (Benchmark Return − Risk-Free Rate)]`. Positive alpha = outperformance. | `1.5`, `−0.8` |
| `beta` | REAL | NULL | Measure of the fund's sensitivity to benchmark movements. `Beta = 1.0` moves in lockstep with the market; `< 1.0` is less volatile; `> 1.0` is more volatile. | `0.85`, `1.12` |
| `sharpe_ratio` | REAL | NULL | Risk-adjusted return per unit of total risk. `Sharpe = (Fund Return − Risk-Free Rate) / Standard Deviation`. Higher is better. Range in dataset: 0.80 – 7.68. | `1.2`, `3.5` |
| `sortino_ratio` | REAL | NULL | Variant of Sharpe ratio that penalises only downside volatility. `Sortino = (Fund Return − Risk-Free Rate) / Downside Deviation`. Preferred for asymmetric return distributions. | `1.8`, `4.2` |
| `std_dev_ann_pct` | REAL | NULL | Annualised standard deviation of daily returns, in %. Measures total volatility of the fund. Higher values indicate greater price swings. | `12.5`, `18.3` |
| `max_drawdown_pct` | REAL | NULL | Largest peak-to-trough decline in NAV over the measurement period, in %. Always negative or zero. Measures worst-case loss an investor could have suffered. | `−22.4`, `−8.1` |
| `aum_crore` | REAL | NULL | Assets Under Management of this scheme in ₹ Crores at the time of the performance snapshot. (1 Crore = ₹10 million.) | `15000`, `45000` |
| `expense_ratio_pct` | REAL | NULL | Total Expense Ratio at the time of snapshot. May differ slightly from `dim_fund.expense_ratio_pct` if updated between snapshots. | `0.55`, `1.25` |
| `morningstar_rating` | INTEGER | NULL | Morningstar star rating for the fund. Risk-adjusted return ranking within peer category. Scale: 3 = Neutral, 4 = Above Average, 5 = Top. (Only 3–5 present in dataset.) | `3`, `4`, `5` |
| `risk_grade` | TEXT | NULL | Qualitative risk classification assigned by the rating agency or internal model, aligned with SEBI risk-o-meter. | `Low`, `Moderate`, `Moderately High`, `High`, `Very High` |

---

### fact_aum

**Description:** Monthly Assets Under Management (AUM) aggregated at fund house level. Captures total industry and fund house AUM trends over time.

**Source:** `cleaned_03_aum_by_fund_house.csv`  
**Row count:** 90  
**Primary key:** `aum_id` (surrogate)  
**Natural key:** `(date_id, fund_house)` — UNIQUE constraint enforced  
**Date range:** Matches `fact_sip_inflows` — monthly from January 2022

| Column | Data Type | Nullable | Business Definition | Example Values |
|--------|-----------|----------|---------------------|----------------|
| `aum_id` | INTEGER | NOT NULL | Auto-incrementing surrogate primary key. | `1`, `2`, … |
| `date_id` | TEXT | NOT NULL | Foreign key → `dim_date.date_id`. Typically month-end date for the reporting period. | `2024-03-31` |
| `fund_house` | TEXT | NOT NULL | Name of the Asset Management Company. Consistent with `dim_fund.fund_house`. | `HDFC Mutual Fund`, `Axis Mutual Fund` |
| `aum_crore` | REAL | NOT NULL | Total AUM managed by this fund house across all schemes, in ₹ Crores. Range in dataset: ₹1,05,000 Cr – ₹12,50,000 Cr. | `500000`, `1250000` |
| `aum_lakh_crore` | REAL | NULL | Convenience column: `aum_crore / 100`. In ₹ Lakh Crore (a common Indian financial reporting unit where 1 Lakh Crore = ₹1 Trillion). | `5.0`, `12.5` |
| `num_schemes` | INTEGER | NULL | Total number of active schemes operated by this fund house in the reporting period. | `18`, `35` |

---

## Extended Fact Tables

### fact_sip_inflows

**Description:** Industry-wide monthly Systematic Investment Plan (SIP) statistics. Aggregated across all fund houses and categories. Tracks the health and growth of India's SIP ecosystem.

**Source:** `cleaned_04_monthly_sip_inflows.csv`  
**Row count:** 48  
**Primary key:** `sip_id` (surrogate)  
**Natural key:** `date_id` — UNIQUE constraint enforced  
**Date range:** January 2022 – December 2025

| Column | Data Type | Nullable | Business Definition | Example Values |
|--------|-----------|----------|---------------------|----------------|
| `sip_id` | INTEGER | NOT NULL | Auto-incrementing surrogate primary key. | `1`, `2`, … |
| `date_id` | TEXT | NOT NULL | Foreign key → `dim_date.date_id`. First day of the reporting month (`YYYY-MM-01`). | `2024-01-01` |
| `sip_inflow_crore` | REAL | NULL | Total SIP instalments collected industry-wide during the month, in ₹ Crores. The headline number reported by AMFI monthly. | `19000`, `21000` |
| `active_sip_accounts_crore` | REAL | NULL | Total number of active (live) SIP mandates/accounts at month-end, in Crores (hundreds of millions). | `0.72`, `0.90` |
| `new_sip_accounts_lakh` | REAL | NULL | New SIP accounts registered during the month, in Lakhs (hundreds of thousands). Measures fresh adoption. | `28.5`, `40.2` |
| `sip_aum_lakh_crore` | REAL | NULL | Portion of total industry AUM attributable to SIP investments, in ₹ Lakh Crore. | `9.5`, `12.3` |
| `yoy_growth_pct` | REAL | NULL | Year-on-year percentage change in `sip_inflow_crore` vs the same month in the prior year. Pre-calculated in the source. Cross-check against computed YoY queries. | `18.5`, `−2.3` |

---

### fact_category_inflows

**Description:** Monthly net inflows broken down by fund category. Net inflow = gross purchases − gross redemptions. Negative values indicate net outflows (redemptions exceed purchases).

**Source:** `cleaned_05_category_inflows.csv`  
**Row count:** 144  
**Primary key:** `cat_inflow_id` (surrogate)  
**Natural key:** `(date_id, category)` — UNIQUE constraint enforced

| Column | Data Type | Nullable | Business Definition | Example Values |
|--------|-----------|----------|---------------------|----------------|
| `cat_inflow_id` | INTEGER | NOT NULL | Auto-incrementing surrogate primary key. | `1`, `2`, … |
| `date_id` | TEXT | NOT NULL | Foreign key → `dim_date.date_id`. First day of the reporting month. | `2024-06-01` |
| `category` | TEXT | NOT NULL | Fund category as per SEBI classification. | `Large Cap`, `Mid Cap`, `Small Cap`, `Flexi Cap`, `ELSS`, `Liquid`, `Gilt`, `Hybrid`, `Large & Mid Cap` |
| `net_inflow_crore` | REAL | NULL | Net investor inflow into this category during the month, in ₹ Crores. Negative = net outflow. | `3500.0`, `−850.0` |

---

### fact_folio_count

**Description:** Monthly industry-level folio count statistics. A folio is a unique investor account within a specific fund house (one investor can hold multiple folios across fund houses). Tracks investor base penetration.

**Source:** `cleaned_06_industry_folio_count.csv`  
**Row count:** 21  
**Primary key:** `folio_id` (surrogate)  
**Natural key:** `date_id` — UNIQUE constraint enforced

| Column | Data Type | Nullable | Business Definition | Example Values |
|--------|-----------|----------|---------------------|----------------|
| `folio_id` | INTEGER | NOT NULL | Auto-incrementing surrogate primary key. | `1`, `2`, … |
| `date_id` | TEXT | NOT NULL | Foreign key → `dim_date.date_id`. First day of the reporting month. | `2024-03-01` |
| `total_folios_crore` | REAL | NULL | Total number of mutual fund folios across the industry at month-end, in Crores. Includes all asset classes. | `16.5`, `18.2` |
| `equity_folios_crore` | REAL | NULL | Folios in equity-oriented schemes (Equity + ELSS), in Crores. Typically ~85% of total folios. | `14.2`, `15.8` |
| `debt_folios_crore` | REAL | NULL | Folios in pure debt / fixed income schemes, in Crores. | `0.8`, `1.1` |
| `hybrid_folios_crore` | REAL | NULL | Folios in hybrid (balanced) schemes, in Crores. | `1.0`, `1.2` |
| `others_folios_crore` | REAL | NULL | Folios in solution-oriented, index, ETF, and other scheme types, in Crores. | `0.3`, `0.5` |

---

### fact_portfolio_holdings

**Description:** Stock-level holdings inside each mutual fund at a given portfolio date. Shows which equities each fund owns, their weight in the portfolio, and current market value. Enables sector concentration and overlap analysis.

**Source:** `cleaned_09_portfolio_holdings.csv`  
**Row count:** 322  
**Primary key:** `holding_id` (surrogate)  
**Natural key:** `(amfi_code, date_id, stock_symbol)` — UNIQUE constraint enforced

| Column | Data Type | Nullable | Business Definition | Example Values |
|--------|-----------|----------|---------------------|----------------|
| `holding_id` | INTEGER | NOT NULL | Auto-incrementing surrogate primary key. | `1`, `2`, … |
| `amfi_code` | INTEGER | NOT NULL | Foreign key → `dim_fund.amfi_code`. The fund that holds this stock. | `100033` |
| `date_id` | TEXT | NOT NULL | Foreign key → `dim_date.date_id`. Portfolio disclosure date (typically last day of month). | `2025-01-31` |
| `stock_symbol` | TEXT | NULL | NSE ticker symbol of the held equity. | `RELIANCE`, `ICICIBANK`, `HINDUNILVR` |
| `stock_name` | TEXT | NULL | Full company name of the holding. | `Reliance Industries Ltd`, `ICICI Bank Ltd` |
| `sector` | TEXT | NULL | Sector classification of the stock. | `Banking`, `IT`, `Pharma`, `Automobile`, `Telecom`, `Utilities`, `Diversified`, `Paints` |
| `weight_pct` | REAL | NULL | Percentage of the fund's total AUM invested in this stock. All holdings sum to ≤ 100% (remainder may be cash/debt instruments). | `8.5`, `3.2` |
| `market_value_cr` | REAL | NULL | Market value of the fund's holding in this stock, in ₹ Crores. `market_value_cr = (fund_aum × weight_pct) / 100`. | `1200.5`, `450.0` |
| `current_price_inr` | REAL | NULL | Market price per share of the stock in ₹ at the portfolio date. | `2450.75`, `890.30` |

---

### fact_benchmark_indices

**Description:** Daily closing values for major Indian market indices. Used to compare fund performance against the market, calculate alpha/beta, and analyse market-wide trends.

**Source:** `cleaned_10_benchmark_indices.csv`  
**Row count:** 8,050  
**Primary key:** `bench_id` (surrogate)  
**Natural key:** `(date_id, index_name)` — UNIQUE constraint enforced  
**Date range:** January 2022 – May 2026

| Column | Data Type | Nullable | Business Definition | Example Values |
|--------|-----------|----------|---------------------|----------------|
| `bench_id` | INTEGER | NOT NULL | Auto-incrementing surrogate primary key. | `1`, `2`, … |
| `date_id` | TEXT | NOT NULL | Foreign key → `dim_date.date_id`. The trading date of the closing price. | `2024-01-15` |
| `index_name` | TEXT | NOT NULL | Identifier for the market index. See [Controlled Vocabularies](#controlled-vocabularies) for full list. | `NIFTY50`, `BSE_SMALLCAP` |
| `close_value` | REAL | NULL | Index closing level on `date_id`. Index values are dimensionless (not in ₹). Use percentage change between two dates to compute returns. | `22450.50`, `48200.00` |

---

## Key Relationships

| Fact Table | Joins to dim_fund via | Joins to dim_date via | Notes |
|---|---|---|---|
| `fact_nav` | `amfi_code` | `date_id` | Core pricing table |
| `fact_transactions` | `amfi_code` | `date_id` | No dim_investor modelled separately |
| `fact_performance` | `amfi_code` | — | Point-in-time snapshot only |
| `fact_aum` | — (fund_house TEXT) | `date_id` | Fund house grain, not scheme grain |
| `fact_sip_inflows` | — | `date_id` | Industry-level only |
| `fact_category_inflows` | — | `date_id` | Category grain, not scheme grain |
| `fact_folio_count` | — | `date_id` | Industry-level only |
| `fact_portfolio_holdings` | `amfi_code` | `date_id` | Stock-level detail |
| `fact_benchmark_indices` | — | `date_id` | No fund FK; join via dim_fund.benchmark |

---

## Controlled Vocabularies

### `dim_fund.category`
| Value | Description |
|-------|-------------|
| `Equity` | Predominantly invested in equity shares of companies |
| `Debt` | Invested in fixed-income instruments (bonds, T-bills, commercial paper) |

### `dim_fund.sebi_category_code`
| Code | Category | Sub-type |
|------|----------|----------|
| `EC01` | Equity | Large Cap |
| `EC02` | Equity | Mid Cap |
| `EC03` | Equity | Small Cap |
| `EC04` | Equity | Flexi Cap |
| `EC05` | Equity | ELSS (Tax saving) |
| `EC06` | Equity | Other Equity |
| `EI01` | Equity | Index / ETF |
| `DC01` | Debt | Liquid |
| `DC02` | Debt | Short Duration |

### `dim_fund.risk_category` / `fact_performance.risk_grade`
| Value | SEBI Colour | Typical Instrument |
|-------|-------------|-------------------|
| `Low` | Blue | Overnight / Liquid funds |
| `Moderate` | Yellow | Short duration debt |
| `Moderately High` | Orange | Hybrid / Large cap equity |
| `High` | Brown | Mid/Small cap equity |
| `Very High` | Red | Sectoral / thematic / small cap |

### `fact_transactions.transaction_type`
| Value | Description |
|-------|-------------|
| `SIP` | Systematic Investment Plan scheduled instalment |
| `Lumpsum` | One-time purchase |
| `Redemption` | Partial or full withdrawal |

### `fact_transactions.city_tier`
| Value | Description |
|-------|-------------|
| `T30` | Top 30 cities by AUM contribution. Higher financial literacy, lower incentives. |
| `B30` | Beyond Top 30. SEBI policy focus for deeper mutual fund penetration. Additional TER benefit given to AMCs for B30 inflows. |

### `fact_benchmark_indices.index_name`
| Value | Full Name | Asset Class |
|-------|-----------|-------------|
| `NIFTY50` | Nifty 50 | Large cap equity |
| `NIFTY100` | Nifty 100 | Large + mid cap equity |
| `NIFTY500` | Nifty 500 | Broad market equity |
| `NIFTY_MIDCAP150` | Nifty Midcap 150 | Mid cap equity |
| `BSE_SMALLCAP` | BSE SmallCap | Small cap equity |
| `CRISIL_GILT` | CRISIL Gilt Index | Government securities |
| `CRISIL_LIQUID` | CRISIL Liquid Fund Index | Liquid / overnight debt |

---

## Source File Reference

| Source CSV | Loaded into | Rows | Date Range |
|---|---|---|---|
| `cleaned_01_fund_master.csv` | `dim_fund` | 40 | — (static master) |
| `Cleaned_02_nav_history.csv` | `fact_nav` | 46,000 | Jan 2022 – May 2026 |
| `cleaned_03_aum_by_fund_house.csv` | `fact_aum` | 90 | Monthly |
| `cleaned_04_monthly_sip_inflows.csv` | `fact_sip_inflows` | 48 | Jan 2022 – Dec 2025 |
| `cleaned_05_category_inflows.csv` | `fact_category_inflows` | 144 | Monthly |
| `cleaned_06_industry_folio_count.csv` | `fact_folio_count` | 21 | Monthly |
| `cleaned_07_scheme_performance.csv` | `fact_performance` | 40 | — (point-in-time snapshot) |
| `cleaned_08_investor_transactions.csv` | `fact_transactions` | 32,778 | Jan 2024 – May 2025 |
| `cleaned_09_portfolio_holdings.csv` | `fact_portfolio_holdings` | 322 | Monthly portfolio disclosures |
| `cleaned_10_benchmark_indices.csv` | `fact_benchmark_indices` | 8,050 | Jan 2022 – May 2026 |
| *(derived)* | `dim_date` | 1,340 | 2 Jan 2022 – 29 May 2026 |

---

*Last updated: June 2026 · Database: `mutual_fund_dw.db` · Total rows: 87,573*
