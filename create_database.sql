create database fintech;
use fintech;

-- create dim date
create table dim_date (
    date_key INT NOT NULL,
    month_name varchar(20) NOT NULL,
    week_number int NOT NULL, -- UPDATE DONE
    day_name varchar(20) NOT NULL,
    quarter varchar(20) NOT NULL,
    is_weekend INT NOT NULL ,
    is_holiday INT NOT NULL,
    CONSTRAINT pk_date primary key(date_key)
);

-- create dim customers
create table dim_customers (
    customer_id varchar(50) NOT NULL,
    customer_bdate  date,
    customer_age INT,
    customer_gender varchar(20),
    customer_location varchar(50),
    CONSTRAINT pk_cust primary key(customer_id)
);

-- create fact_transaction
create table fact_transaction (
    transaction_id varchar(50) ,
    customer_id varchar(50) NOT NULL,
    date_key INT NOT NULL,
    transaction_amount DECIMAL(18, 2) NOT NULL,
    transaction_time time(7) NOT NULL, 
    transaction_date date NOT NULL,
    customer_account_balance DECIMAL(18, 2) NOT NULL,
    CONSTRAINT pk_trans_id primary key(transaction_id),
    CONSTRAINT fk_date foreign key(date_key) references dim_date(date_key),
    CONSTRAINT fk_cust foreign key(customer_id) references dim_customers(customer_id)
);