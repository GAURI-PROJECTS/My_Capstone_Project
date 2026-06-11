
select scheme_name,
		sum(aum_crore)
        from dim_fund join fact_aum on dim_fund.fund_house=fact_aum.fund_house 
group by scheme_name
order by aum_crore
LIMIT 5