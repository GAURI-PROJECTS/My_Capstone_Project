
/* 1. Top 5 funds by AUM*/

select scheme_name,
		sum(aum_crore)
        from dim_fund join fact_aum on dim_fund.fund_house=fact_aum.fund_house 
group by scheme_name
order by aum_crore
LIMIT 5



/* 2. Average NAV per month */

SELECT
    d.year,
    d.month,
    d.month_name,
    f.scheme_name,
    f.category,
    ROUND(AVG(n.nav), 4) AS avg_nav
FROM fact_nav n
JOIN dim_date d ON n.date_id = d.date_id
JOIN dim_fund  f ON n.amfi_code = f.amfi_code
GROUP BY d.year, d.month, d.month_name, n.amfi_code, f.scheme_name, f.category
ORDER BY d.year, d.month, f.scheme_name;


/* 3. write query to find SIP YoY growth*/

-select yoy_growth_pct from SIP_inflows

or

-SELECT d.year, d.month, d.month_name,
       ROUND(AVG(n.nav), 4) AS avg_nav_all_funds
FROM fact_nav n
JOIN dim_date d ON n.date_id = d.date_id
GROUP BY d.year, d.month
ORDER BY d.year, d.month;



/* 4. write a query to find transactions by state */

SELECT
    state,
    COUNT(*) AS transaction_count,
    ROUND(SUM(amount_inr), 2) AS total_amount,
    ROUND(AVG(amount_inr), 2) AS avg_transaction_amount
FROM fact_transactions
GROUP BY state
ORDER BY total_amount DESC;



/* 5. write a query to find funds with expense_ratio < 1% */

select df.scheme_name,
	fp.expense_ratio_pct
    from dim_fund df JOIN fact_performance fp on df.amfi_code= fp.amfi_code
    WHERE fp.expense_ratio_pct <1
    order by fp.expense_ratio_pct



/* 6. State-wise SIP Transactions Only */


SELECT
    state,
    COUNT(*) AS sip_transactions,
    ROUND(SUM(amount_inr), 2) AS sip_amount
FROM fact_transactions
WHERE UPPER(transaction_type) = 'SIP'
GROUP BY state
ORDER BY sip_amount DESC;


/* 7. Find the best-performing funds based on long-term returns.*/


SELECT
    f.scheme_name,
    f.fund_house,
    p.return_5yr_pct
FROM fact_performance p
JOIN dim_fund f
    ON p.amfi_code= f.amfi_code
WHERE p.return_5yr_pct IS NOT NULL
ORDER BY p.return_5yr_pct DESC
LIMIT 10;


/* 8.See how funds are distributed across risk levels.10. Fund Count by Risk Grade*/

SELECT
    risk_grade,
    COUNT(*) AS fund_count
FROM fact_performance JOIN dim_fund on fact_performance.amfi_code=dim_fund.amfi_code
GROUP BY risk_grade
ORDER BY fund_count DESC;


/* 9. Redemption vs SIP Amount*/


SELECT
    transaction_type,
    COUNT(*) AS transaction_count,
    ROUND(SUM(amount_inr), 2) AS total_amount
FROM fact_transactions
GROUP BY transaction_type
ORDER BY total_amount DESC;


/* 10. Identify categories with higher average NAV.*/

SELECT
    category,
    ROUND(AVG(nav), 2) AS avg_nav
FROM fact_nav 
JOIN dim_fund
    ON fact_nav.amfi_code= fact_nav.amfi_code
GROUP BY category
ORDER BY avg_nav DESC;


