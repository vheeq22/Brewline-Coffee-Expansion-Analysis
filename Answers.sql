-- Brewline Coffee Analysis

SELECT * FROM city;
SELECT * FROM products;
SELECT * FROM customers;
SELECT * FROM sales;

-- Reports & Data Analysis

-- Q.1 Coffee Consumers Count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?

SELECT 
	city_name,
    ROUND((population * 0.25) / 1000000, 2) AS est_coffee_consumer,
    city_rank
FROM city
ORDER BY 2 DESC;


-- Q.2 Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

SELECT
	SUM(total) as total_revenue
FROM sales
WHERE
	year(sale_date) = 2023
    AND
    quarter(sale_date) = 4;


SELECT
	ci.city_name,
	SUM(s.total) as total_revenue
FROM sales s 
	JOIN customers c 
    ON c.customer_id = s.customer_id
    JOIN city ci 
    ON ci.city_id = c.city_id
WHERE
	year(s.sale_date) = 2023
    AND
    quarter(s.sale_date) = 4
GROUP BY 1
ORDER BY 2 DESC;


-- Q.3 Sales Count for Each Product
-- How many units of each coffee product have been sold?

SELECT
	p.product_name,
    COUNT(s.sale_id) as total_orders
FROM products p 
	JOIN 
		sales s 
	ON s.product_id = p.product_id
GROUP BY 1
ORDER BY 2 DESC;


-- Q.4 Average Sales Amount per City
-- What is the average sales amount per customer in each city?

SELECT
	ci.city_name,
	SUM(s.total) as total_revenue,
    COUNT(DISTINCT s.customer_id) as unique_cstr,
    ROUND(SUM(s.total)/ COUNT(DISTINCT s.customer_id), 2) as avg_sale_per_cstr
FROM sales s 
	JOIN customers c 
    ON c.customer_id = s.customer_id
    JOIN city ci 
    ON ci.city_id = c.city_id
GROUP BY 1
ORDER BY 2 DESC;


-- Q.5 City Population and Coffee Consumers
-- Provide a list of cities along with their populations and estimated coffee consumers.

SELECT 
	ct.city_name,
    ROUND((ct.population * 0.25)/ 1000000, 2) as coffee_consumers,
    COUNT(DISTINCT c.customer_id) as unique_cstr
FROM city ct 
	JOIN customers c 
    ON c.city_id = ct.city_id
GROUP BY 1,2
ORDER BY 2 DESC;


-- Q.6 Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?

SELECT *
FROM
(SELECT 
	ci.city_name,
    p.product_name,
    COUNT(s.sale_id) as total_orders,
    DENSE_RANK() OVER(PARTITION BY ci.city_name ORDER BY COUNT(s.sale_id) DESC) as rnk
FROM sales s 
	JOIN products p 
    ON s.product_id = p.product_id
	JOIN customers c 
    ON c.customer_id = s.customer_id
    JOIN city ci 
    ON ci.city_id = c.city_id
GROUP BY 1,2
) as t1
WHERE rnk <= 3;


-- Q.7 Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?

SELECT 
	ct.city_name,
    COUNT(DISTINCT c.customer_id) as unique_cstr
FROM city ct 
	JOIN customers c 
    ON c.city_id = ct.city_id
    JOIN sales s
    ON s.customer_id = c.customer_id
WHERE s.product_id BETWEEN 1 AND 14
GROUP BY 1;


-- Q.8 Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer

SELECT
	t1.city_name,
    t1.estimated_rent,
    t1.unique_cstr,
    t1.avg_sale_per_cstr,
    ROUND(t1.estimated_rent/ t1.unique_cstr, 2) as avg_rent_per_cstr
FROM
(SELECT
	ci.city_name,
    ci.estimated_rent,
	SUM(s.total) as total_revenue,
    COUNT(DISTINCT s.customer_id) as unique_cstr,
    ROUND(SUM(s.total)/ COUNT(DISTINCT s.customer_id), 2) as avg_sale_per_cstr
FROM sales s 
	JOIN customers c 
    ON c.customer_id = s.customer_id
    JOIN city ci 
    ON ci.city_id = c.city_id
GROUP BY 1,2
) as t1
ORDER BY 5 DESC;


-- Q.9 Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly) by each city.

SELECT
	b.city_name,
    b.month,
    b.year,
    b.cr_month_sale,
    b.last_month_sale,
    ROUND((b.cr_month_sale-b.last_month_sale)/b.last_month_sale * 100, 2) as growth_ratio
FROM
(SELECT 
	a.city_name,
    a.month,
    a.year,
    a.total_sale as cr_month_sale,
    LAG(a.total_sale, 1) OVER(PARTITION BY a.city_name ORDER BY  a.year, a.month) as last_month_sale
FROM 
(
SELECT
	ci.city_name,
    MONTH(s.sale_date) as month,
    YEAR(s.sale_date) as Year,
    SUM(s.total) as total_sale
FROM sales s 
	JOIN customers c 
    ON s.customer_id = c.customer_id
    JOIN city ci 
    ON ci.city_id = c.city_id
GROUP BY 1, 2, 3
ORDER BY 1, 3, 2
) AS a
) AS b
WHERE b.last_month_sale IS NOT NULL;


-- Q.10 Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer

SELECT
	t1.city_name,
    t1.total_revenue,
    t1.estimated_rent as total_rent,
    t1.total_cstr,
    t1.est_coffee_consumer,
    t1.avg_sale_per_cstr,
    ROUND(t1.estimated_rent/ t1.total_cstr, 2) as avg_rent_per_cstr
FROM
(SELECT
	ci.city_name,
    ci.estimated_rent,
    ROUND((ci.population * 0.25)/ 1000000, 3) as est_coffee_consumer,
	SUM(s.total) as total_revenue,
    COUNT(DISTINCT s.customer_id) as total_cstr,
    ROUND(SUM(s.total)/ COUNT(DISTINCT s.customer_id), 2) as avg_sale_per_cstr
FROM sales s 
	JOIN customers c 
    ON c.customer_id = s.customer_id
    JOIN city ci 
    ON ci.city_id = c.city_id
GROUP BY 1, 2, 3
) as t1
ORDER BY 2 DESC;



/* 
-- RECOMENDATIONS
City 1: Pune
	1.Highest total revenue.
	2.Highest average sale per customer.
	3.Average rent per customer is  very low.

City 2: Chennai
	1.Second highest total revenue.
	2.Second highest average sale per customer.
	3.Average rent per customer is at 407.

City 3:Delhi 
	1.Highest estimated coffee consumers at 7.7m.
	2.Second highest total customers at 68.
	3.Average rent per customer is good at 330.

City 4:Jaipur 
	1.Highest total customer at 69.
	2.Lowest average rent per cost at 156.
	3.Average sale per customer is better at 11.6k.
/*
