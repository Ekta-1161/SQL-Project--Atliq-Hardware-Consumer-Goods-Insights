# Q1 Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.
select distinct market 
from dim_customer
where (customer = 'Atliq Exclusive') 
and  (region = 'APAC')

# Q2 What is the percentage of unique product increase in 2021 vs. 2020;
with unique_2020 as (select count(distinct(product_code)) as unique_count
		from fact_sales_monthly
		where fiscal_year = '2020'),
	unique_2021 as (select count(distinct(product_code)) as unique_count
		from fact_sales_monthly
		where fiscal_year = '2021')

select a.unique_count as unique_products_2020,
	   b.unique_count as unique_products_2021,
        concat(round((b.unique_count - a.unique_count) / a.unique_count*100,2),'%') as percentage_chg
from unique_2020 as a
join unique_2021 as b;

# Q3 all the unique product counts for each segment and sort them in descending order of product counts. 
select segment, count(distinct product_code) as product_count
from dim_product
group by segment
order by product_count desc	

# Q4 Which segment had the most increase in unique products in 2021 vs 2020?
with 2021_ as (select p.segment, count(distinct p.product_code) as products , s.fiscal_year
				from dim_product as p
                join fact_sales_monthly as s
                on p.product_code = s.product_code
                where fiscal_year = 2021
                group by segment),
        
	 2020_ as (select p.segment, count(distinct p.product_code)as products, s.fiscal_year
				from dim_product as p
                join fact_sales_monthly as s
                on p.product_code = s.product_code
                where fiscal_year = 2020
                group by segment)
select a.segment, a.products as product_count_2020 , b.products as product_count_2021, (b.products - a.products) as difference,
	concat(round((b.products - a.products) / b.products*100,2),'%') as percentage_chg
from 2021_ as b
join 2020_ as a
on a.segment = b.segment
order by difference

# Q5 the products that have the highest and lowest manufacturing costs
select m.product_code,p.product, p.segment, m.manufacturing_cost
from dim_product as p
join fact_manufacturing_cost as m
on m.product_code=p.product_code
where manufacturing_cost = (select min(manufacturing_cost) from fact_manufacturing_cost) 
     or manufacturing_cost = (select max(manufacturing_cost) from fact_manufacturing_cost) 
     

# Q6 which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market.

select i.customer_code, c.customer, 
       round(i.pre_invoice_discount_pct*100, 2) as average_discount_pct, 
       i.fiscal_year
from fact_pre_invoice_deductions as i
join dim_customer as c
on i.customer_code=c.customer_code
where (fiscal_year = 2021) and (market = 'india')
order by average_discount_pct desc
limit 5

# Q7 the Gross sales amount for the customer “Atliq Exclusive” for each month. 

SELECT 
	MONTHNAME(s.date) as Month,
	YEAR(s.date) AS Year,
    round(sum(sold_quantity*gross_price)/1000000, 2) as gross_sales_mln
FROM fact_sales_monthly s
JOIN fact_gross_price g
ON g.product_code=s.product_code
JOIN dim_customer c
ON c.customer_code=s.customer_code
where customer="Atliq Exclusive"
group by Month, Year
order by Year;

# Q8  In which quarter of 2020, got the maximum total_sold_quantity? 

select case when month(date) in (9,10,11) then "Quarter 1"
	when month(date) in (12,1,2) then "Quarter 2"
    when month(date) in (3,4,5) then "Quarter 3"
    when month(date) in (6,7,8) then "Quarter 4"
end as Quarter, sum(sold_quantity) as total_sold_quantity
from fact_sales_monthly
where fiscal_year = 2020
group by Quarter
order by total_sold_quantity desc

# Q9 Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution?

with channel_contri as 
(select c.channel as channel, 
		round(sum(g.gross_price* m.sold_quantity)/1000000,2)  as gross_sales_mln
from dim_customer as c 
join fact_sales_monthly as m 
   on c.customer_code = m.customer_code 
join fact_gross_price as g 
   on m.product_code = g.product_code and g.fiscal_year = m.fiscal_year
where m.fiscal_year = 2021
group by channel
order by gross_sales_mln desc)

select *,
concat(round(gross_sales_mln * 100 /(
select sum(gross_sales_mln) from channel_contri), 2),"%") 
			as 'percentage_of_contribution'
from channel_contri
   

# Q10 Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021

WITH division_sales_cte AS 
	(
    SELECT p.division, s.product_code,p.product, 
           SUM(s.sold_quantity) AS 'total_sold_qty', 
	row_number()
    OVER (PARTITION BY p.division 
            ORDER BY sum(s.sold_quantity) DESC) AS rank_order
	FROM fact_sales_monthly AS s 
	INNER JOIN dim_product AS p
	ON s.product_code = p.product_code
	WHERE s.fiscal_year = 2021
	GROUP BY p.division, s.product_code, p.product
    )
SELECT division, product_code, product, total_sold_qty, rank_order
FROM division_sales_cte
WHERE rank_order <= 3;






