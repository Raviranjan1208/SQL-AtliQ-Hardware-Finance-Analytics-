use gdb0041;

-- 1) Croma india product wise sales report for fiscal year - 2021.
-- Month => fact_sales_monthly 
-- Product Name => dim_product
-- Variant => dim_product
-- Sold Quantity => fact_sales_monthly
-- Gross Price Per Item => fact_gross_price
-- Gross Price Total => calculated_column

-- Ans

-- so firstly we have to find customer code for croma
select * from dim_customer
where customer like 'croma%';

-- and we looking for the sales report then go through fact_sales_monthly table
select monthname(s.date) as Month,
	s.Product_code, p.Product, p.Variant,
	s.Sold_quantity, 
	round(g.gross_price,2) as Gross_price,
	round(g.gross_price*s.sold_quantity,2)
    as Gross_price_total
from fact_sales_monthly s
join dim_product p
on p.product_code = s.product_code
join fact_gross_price g
on g.product_code = s.product_code and
   g.fiscal_year = get_fiscal_year(s.date)
where
     customer_code = 90002002 and
     get_fiscal_year(date) = 2021
order by date asc
limit 100000;

-- 2) Gross monthly total sales report for croma
-- Month
-- Total gtoss sales amount

-- Ans

select monthname(s.date) as Month, 
	   round(sum(s.sold_quantity*g.gross_price),2)
       as Total_monthly_gross_amount
from fact_sales_monthly s
join fact_gross_price g
on g.product_code = s.product_code and
   g.fiscal_year = get_fiscal_year(s.date)
where customer_code = 90002002
group by s.date
order by s.date asc;

-- 3) yearly report for Croma India where there are two columns
-- 1. Fiscal Year
-- 2. Total Gross Sales amount In that year from Croma

-- Ans

select g.fiscal_year, round(sum(s.sold_quantity*g.gross_price)/1000000,2) as "Total_gross_sales_amount(Million)"
from fact_sales_monthly s
join fact_gross_price g
on g.product_code = s.product_code and g.fiscal_year = get_fiscal_year(s.date)
where customer_code = 90002002
group by g.fiscal_year;


-- 4) Top markets, product, customers for a given financial year ( by nat sales)
-- Net Sales = Gross price - pre invoce deduction - post incoice deductions

-- Ans  Top Market

select market,
	   round(sum(net_sales)/1000000,2) as net_sales_million
from net_sales
where fiscal_year = 2021
group by market
order by net_sales_million desc
limit 5;

-- Ans  Top Customer

select c.customer,
	   round(sum(net_sales)/1000000,2) as net_sales_million
from net_sales n
join dim_customer c
on n.customer_code = c.customer_code
where fiscal_year = 2021
group by c.customer
order by net_sales_million desc
limit 5;

-- Ans  Top Product

select product,
	   round(sum(net_sales)/1000000,2) as net_sales_million
from net_sales
where fiscal_year = 2021
group by product
order by net_sales_million desc
limit 5;

-- 5) Net Sales % share global by customer

-- Ans 

with cte as(
select c.customer,
		round(sum(net_sales)/1000000,2) as net_sales_million
	from net_sales n
	join dim_customer c
	on n.customer_code = c.customer_code
	where fiscal_year = 2021
	group by c.customer
	order by net_sales_million desc)
    
select 
	*,
    round(net_sales_million*100/sum(net_sales_million) over(),2) as net_sales_perc
from cte
order by net_sales_million desc
limit 10;

-- 6) Net Sales % share by region

-- Ans

with cte as(
select c.customer,
	   c.region,
		round(sum(net_sales)/1000000,2) as net_sales_million
	from net_sales n
	join dim_customer c
	on n.customer_code = c.customer_code
	where fiscal_year = 2021
	group by c.customer, c.region
	order by net_sales_million desc)
    
select 
	*,
    round(net_sales_million*100/sum(net_sales_million) over(partition by region),2) as pct_share_region
from cte
order by region, net_sales_million desc;

-- Ans region - APAC

with cte as(
select c.customer,
	   c.region,
		round(sum(net_sales)/1000000,2) as net_sales_million
	from net_sales n
	join dim_customer c
	on n.customer_code = c.customer_code
	where fiscal_year = 2021 and region = "APAC"
	group by c.customer, c.region
	order by net_sales_million desc)
    
select customer,
    round(net_sales_million*100/sum(net_sales_million) over(partition by region),2) as pct_share_region
from cte
limit 10;

-- 7) Top 2 market in every region by their gross sales amount

-- Ans

with cte1 as (
select c.region, c.market,
sum(g.gross_price_total) as gross_sales_total
from gross_sales g
join dim_customer c
on g.customer_code = c.customer_code
group by 1,2
),

cte2 as (
select *, dense_rank() over(partition by region
order by gross_sales_total desc) as rnk
from cte1)

select * from cte2
where rnk <= 2;


































