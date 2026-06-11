schema.sql



CREATE TABLE dim_fund(
    amfi_code           INTEGER     PRIMARY KEY,
    fund_house          TEXT        NOT NULL,
    scheme_name         TEXT        NOT NULL,
    category            TEXT,                      
    sub_category        TEXT,
    plan                TEXT,                  
    launch_date         DATE,
    benchmark           TEXT,
    expense_ratio_pct   REAL,
    exit_load_pct       REAL,
    min_sip_amount      INTEGER,
    min_lumpsum_amount  INTEGER,
    fund_manager        TEXT,
    risk_category       TEXT,
    sebi_category_code  TEXT
);


CREATE TABLE dim_date(
    date_id     TEXT    PRIMARY KEY,  				
    year        INTEGER NOT NULL,
    quarter     INTEGER NOT NULL,      				
    month       INTEGER NOT NULL,   				
    month_name  TEXT    NOT NULL,
    week        INTEGER NOT NULL,  			 
    day         INTEGER NOT NULL,
    day_name    TEXT    NOT NULL,
    is_month_end INTEGER NOT NULL DEFAULT 0  			
);
 


CREATE TABLE fact_nav(
    nav_id          INTEGER PRIMARY KEY AUTOINCREMENT,
    amfi_code       INTEGER NOT NULL REFERENCES dim_fund(amfi_code),
    date_id         TEXT    NOT NULL REFERENCES dim_date(date_id),
    nav             REAL    NOT NULL,
    UNIQUE (amfi_code, date_id)
);


CREATE TABLE fact_transactions(
    txn_id              INTEGER PRIMARY KEY AUTOINCREMENT,
    investor_id         TEXT    NOT NULL,
    amfi_code           INTEGER NOT NULL REFERENCES dim_fund(amfi_code),
    date_id             TEXT    NOT NULL REFERENCES dim_date(date_id),
    transaction_type    TEXT    NOT NULL,   -- Purchase / Redemption / Switch-In / Switch-Out / SIP
    amount_inr          REAL NOT NULL,
    state               TEXT,
    city                TEXT,
    city_tier           TEXT,
    age_group           TEXT,
    gender              TEXT,
    annual_income_lakh  REAL,
    payment_mode        TEXT,
    kyc_status          TEXT
);

CREATE TABLE fact_performance(
    perf_id             INTEGER PRIMARY KEY AUTOINCREMENT,
    amfi_code           INTEGER NOT NULL REFERENCES dim_fund(amfi_code),
    scheme_name         TEXT,
    fund_house          varchar(100),
    category            varchar(50),
    plan                varchar(50),
    return_1yr_pct      REAL,
    return_3yr_pct      REAL,
    return_5yr_pct      REAL,
    benchmark_3yr_pct   REAL,
    alpha               REAL,
    beta                REAL,
    sharpe_ratio        REAL,
    sortino_ratio       REAL,
    std_dev_ann_pct     REAL,
    max_drawdown_pct    REAL,
    aum_crore           REAL,
    expense_ratio_pct   REAL,
    morningstar_rating  INTEGER,
    risk_grade          TEXT
);
 

CREATE TABLE fact_aum(
    aum_id          INTEGER PRIMARY KEY AUTOINCREMENT,
    date_id         TEXT    NOT NULL REFERENCES dim_date(date_id),
    fund_house      TEXT    NOT NULL,
    aum_crore       REAL    NOT NULL,
    aum_lakh_crore  REAL,
    num_schemes     INTEGER,
    UNIQUE (date_id, fund_house)
);

 
CREATE TABLE fact_category_inflows(
    cat_inflow_id       INTEGER PRIMARY KEY AUTOINCREMENT,
    date_id             TEXT    NOT NULL REFERENCES dim_date(date_id),
    category            TEXT    NOT NULL,
    net_inflow_crore    REAL,
    UNIQUE (date_id, category)
);
 
CREATE TABLE fact_folio_count(
    folio_id                INTEGER PRIMARY KEY AUTOINCREMENT,
    date_id                 TEXT    NOT NULL REFERENCES dim_date(date_id),
    total_folios_crore      REAL,
    equity_folios_crore     REAL,
    debt_folios_crore       REAL,
    hybrid_folios_crore     REAL,
    others_folios_crore     REAL,
    UNIQUE (date_id)
);


CREATE fact_portfolio_holdings(
    holding_id          INTEGER PRIMARY KEY AUTOINCREMENT,
    amfi_code           INTEGER NOT NULL REFERENCES dim_fund(amfi_code),
    date_id             TEXT    NOT NULL REFERENCES dim_date(date_id),
    stock_symbol        TEXT,
    stock_name          TEXT,
    sector              TEXT,
    weight_pct          REAL,
    market_value_cr     REAL,
    current_price_inr   REAL,
    UNIQUE (amfi_code, date_id, stock_symbol)
);


CREATE TABLE fact_benchmark_indices(
    bench_id        INTEGER PRIMARY KEY AUTOINCREMENT,
    date_id         TEXT    NOT NULL REFERENCES dim_date(date_id),
    index_name      TEXT    NOT NULL,
    close_value     REAL,
    UNIQUE (date_id, index_name)
);



	