-- Counting missing values
SELECT
	count(*) total_rows,
	count(i.description) count_description,
	count(f.listing_price) count_listing_price,
	count(t.last_visited) count_last_visited
FROM
	info i
JOIN finance f
		USING(product_id)
JOIN traffic t
		USING(product_id);
		
-- How do the price points of Nike and Adidas products differ?
SELECT
	b.brand,
	CAST(f.listing_price AS integer),
	count(f.*)
FROM
	brands b
JOIN finance f
		USING(product_id)
WHERE
	f.listing_price > 0
GROUP BY
	b.brand,
	f.listing_price
ORDER BY
	f.listing_price DESC;
	
-- Lebelling price ranges
SELECT
	b.brand,
	count(f.*),
	sum(f.revenue) total_revenue,
	CASE
		WHEN f.listing_price < 42 THEN 'Budget'
		WHEN f.listing_price >= 42
		AND f.listing_price < 72 THEN 'Average'
		WHEN f.listing_price >= 74
		AND f.listing_price < 129 THEN 'Expensive'
		WHEN f.listing_price >= 129 THEN 'Elite'
	END AS price_category
FROM
	brands b
JOIN finance f
		USING(product_id)
WHERE
	b.brand IS NOT NULL
GROUP BY
	b.brand,
	price_category
ORDER BY
	total_revenue DESC;

-- Average discount by brand
SELECT
	b.brand,
	avg(f.discount)* 100 average_discount
FROM
	brands b
JOIN finance f
		USING(product_id)
WHERE
	b.brand IS NOT NULL
GROUP BY
	b.brand;

-- Finding correlation between revenue and reviews
SELECT
	CORR(r.reviews, f.revenue) review_revenue_corr
FROM
	reviews r
JOIN finance f
		USING(product_id);

-- Ratings and reviews by product description length
SELECT
	trunc(length(i.description), -2) description_length,
	round(avg(r.rating::NUMERIC), 2) average_rating
FROM
	info i
JOIN reviews r
		USING(product_id)
WHERE
	i.description IS NOT NULL
GROUP BY
	description_length
ORDER BY
	description_length;

-- Review by month and brand
SELECT
	b.brand,
	date_part('month', t.last_visited) AS MONTH,
	count(r.*) num_reviews
FROM
	brands b
JOIN traffic t
		USING (product_id)
JOIN reviews r
		USING (product_id)
GROUP BY
	b.brand,
	MONTH
HAVING
	b.brand IS NOT NULL
	AND date_part('month', t.last_visited) IS NOT NULL
ORDER BY
	b.brand,
	MONTH;

-- Footwear product performance
WITH footwear AS(
SELECT
	i.description,
	f.revenue
FROM
	info i
JOIN finance f
		USING (product_id)
WHERE
	i.description ILIKE '%shoe%'
	OR
            i.description ILIKE '%trainer%'
	OR
            i.description ILIKE '%foot%'
	AND
    i.description IS NOT NULL
)
SELECT
	count(*) AS num_footwear_products,
	percentile_disc(0.5) WITHIN GROUP (
	ORDER BY revenue) median_footwear_revenue
FROM
	footwear;

-- Clothing product performance
WITH footwear AS(
SELECT
	i.description,
	f.revenue
FROM
	info i
JOIN finance f
		USING (product_id)
WHERE
	i.description ILIKE '%shoe%'
	OR
            i.description ILIKE '%trainer%'
	OR
            i.description ILIKE '%foot%'
	AND
    i.description IS NOT NULL
)
SELECT
	count(i.*) num_clothing_products,
	percentile_disc(0.5) WITHIN GROUP (
	ORDER BY f.revenue) AS median_clothing_revenue
FROM
	info i
JOIN finance f
		USING(product_id)
WHERE
	i.description NOT IN (
	SELECT
		description
	FROM
		footwear);