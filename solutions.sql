--DATA ANAYLSIS

--Q1 
--HOW MANY PEOPLE IN EACH CITY ARE ESTIMATED TO CONSUME COFFEE, GIVEN THAT 25% OF THE POPULATION DOES?

select city_name, population * 0.25 
from city
order by population desc;

--Q2
--WHAT IS THE TOTAL REVENUE GENERATED FROM COFFEE SALES ACROSS ALL CITIES IN THE LAST QUARTER OF 2023?

select *, extract(year from sale_date) as year,
extract(quarter from sale_date) as qtr
from sales;

select ci.city_name, sum(total) as revenue
from sales as s
join customers as c 
on s.customer_id = c.customer_id
join city as ci
on c.city_id= ci.city_id
where
 extract(year from sale_date) = 2023
and 
 extract(quarter from sale_date) = 4
 group by ci.city_name
 order by total desc;

--Q3
--HOW MANY UNITS OF EACH COFFEE PRODUCT HAVE BEEN SOLD?

select count(s.sale_id), p.product_name
  from sales as s
  join products as p
  on s.product_id = p.product_id
 group by p.product_name
 order by count(s.sale_id) desc;

--Q4
--WHAT IS THE AVERAGE SALES AMOUNT PER CUSTOMER IN EACH CITY?

select sum(s.total), ci.city_name, count(distinct s.customer_id) as count,
 SUM(s.total) / count(distinct s.customer_id) as avg_sale_pr_c
 from sales as s
 join customers as c
 on s.customer_id = c.customer_id
 join city as ci
 on c.city_id = ci.city_id
 group by ci.city_name;

--Q5
--PROVIDE A LIST OF CITIES ALONG WITH THEIR POPULATION AND ESTIMATED COFFEE CONSUMERS.

select ci.city_name, ci.population, count(distinct s.customer_id),
 ci.population*0.25 as coffee_consumers
 from city as ci
 join customers as c
 on ci.city_id = c.city_id
 join sales as s
 on c.customer_id = s.customer_id
 group by ci.city_name;

--Q6
--WHAT ARE THE TOP 3 SELLING PRODUCTS IN EACH CITY BASED ON SALES VOLUME?

SELECT 
    city_name,
    product_name,
    sale_count,
    DENSE_RANK() OVER (PARTITION BY city_name ORDER BY sale_count DESC) AS rank
FROM (
    SELECT 
        ci.city_name,
        p.product_name,
        COUNT(s.sale_id) AS sale_count
    FROM sales AS s
    JOIN products AS p ON s.product_id = p.product_id
    JOIN customers AS c ON s.customer_id = c.customer_id
    JOIN city AS ci ON c.city_id = ci.city_id
    GROUP BY ci.city_name, p.product_name
) AS sales_summary
WHERE DENSE_RANK() OVER (PARTITION BY city_name ORDER BY sale_count DESC) <= 3
ORDER BY city_name, sale_count DESC;

--Q7
--CALCULATE THE PERCENTAGE GROWTH (OR DECLINE) IN SALES OVER DIFFERENT TIME PERIOD (MONTHLY)

with
monthly_sales
AS
(
	SELECT 
		ci.city_name,
		EXTRACT(MONTH FROM sale_date) as month,
		EXTRACT(YEAR FROM sale_date) as YEAR,
		SUM(s.total) as total_sale
	FROM sales as s
	JOIN customers as c
	ON c.customer_id = s.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1, 2, 3
	ORDER BY 1, 3, 2
),
growth_ratio
AS
(
		SELECT
			city_name,
			month,
			year,
			total_sale as cr_month_sale,
			LAG(total_sale, 1) OVER(PARTITION BY city_name ORDER BY year, month) as last_month_sale
		FROM monthly_sales
)

SELECT
	city_name,
	month,
	year,
	cr_month_sale,
	last_month_sale,
	ROUND(
		(cr_month_sale-last_month_sale)::numeric/last_month_sale::numeric * 100
		, 2
		) as growth_ratio

FROM growth_ratio

--Q8
--IDENTIFY TOP CITY BASED ON HIGHEST SALES, RETURN CITY NAME, TOTAL SALE,TOTAL RENT, TOTAL CUSTOMERS, ESTIMATED COFFEE CONSUMERS

SELECT 
    cr.city_name,
    ct.total_revenue,
    cr.estimated_rent AS total_rent,
    ct.total_cx,
    cr.estimated_coffee_consumer_in_millions,
    ct.avg_sale_pr_cx,
    ROUND(cr.estimated_rent / NULLIF(ct.total_cx, 0), 2) AS avg_rent_per_cx
FROM (
    SELECT 
        ci.city_name,
        SUM(s.total) AS total_revenue,
        COUNT(DISTINCT s.customer_id) AS total_cx,
        ROUND(SUM(s.total) / COUNT(DISTINCT s.customer_id), 2) AS avg_sale_pr_cx
    FROM sales AS s
    JOIN customers AS c ON s.customer_id = c.customer_id
    JOIN city AS ci ON ci.city_id = c.city_id
    GROUP BY ci.city_name
) AS ct
JOIN (
    SELECT 
        city_name, 
        estimated_rent,
        ROUND((population * 0.25) / 1000000, 3) AS estimated_coffee_consumer_in_millions
    FROM city
) AS cr
ON cr.city_name = ct.city_name
ORDER BY ct.total_revenue DESC;

