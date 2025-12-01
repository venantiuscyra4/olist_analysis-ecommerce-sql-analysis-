# E-Commerce Revenue & Customer Behavior Analytics

-- The goal of this project is to analyze an e-commerce company’s user behavior, marketing effectiveness, and revenue performance using SQL.
-- The company wants to understand:
		-- 1. How much revenue are we generating?
		-- 2. Which marketing channels drive the highest conversions?
		-- 3. Which countries contribute the most active and profitable customers?
		-- 4. What is the retention behavior of customers after signing up?
        -- 5. Which product categories generate the most revenue?
        -- 6. What is the lifetime value (LTV) of our customers?
        -- 7. What does our conversion funnel look like from session → purchase?
        -- 8. Are users coming back repeatedly or leaving after one order?
        -- 9. Which products are often purchased together (product affinity analysis)?
        
        
# Let's use the dataset of Brazilian E-Commerce Public Dataset by Olist 

CREATE DATABASE IF NOT EXISTS olist;
USE olist;

# importing the csv files using the table wizard feature in mysql
SHOW TABLES;

# Basic Exploration
-- Row counts per table
SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL
SELECT 'sellers', COUNT(*) FROM sellers
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL
SELECT 'payments', COUNT(*) FROM payments
UNION ALL
SELECT 'reviews', COUNT(*) FROM reviews
UNION ALL
SELECT 'geolocation', COUNT(*) FROM geolocation;

-- Orders over time
SELECT 
    DATE(order_purchase_timestamp) AS order_date,
    COUNT(*) AS num_orders
FROM orders
GROUP BY DATE(order_purchase_timestamp)
ORDER BY order_date;

-- Customers by state
SELECT 
    customer_state,
    COUNT(*) AS num_customers
FROM customers
GROUP BY customer_state
ORDER BY num_customers DESC;

-- Overview
SELECT
    COUNT(*) AS total_orders,
    SUM(oi.price) AS total_revenue,
    AVG(oi.price) AS avg_item_price
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered';


# Sales & Revenue Analysis
-- Revenue per order
CREATE OR REPLACE VIEW order_revenue AS
SELECT
    o.order_id,
    o.customer_id,
    o.order_status,
    o.order_purchase_timestamp,
    SUM(oi.price) AS order_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY o.order_id, o.customer_id, o.order_status, o.order_purchase_timestamp;

SELECT * FROM order_revenue LIMIT 10;

-- Monthly revenue and order count
SELECT
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m-01') AS month,
    COUNT(*) AS num_orders,
    SUM(order_revenue) AS total_revenue,
    AVG(order_revenue) AS avg_order_value
FROM order_revenue
WHERE order_status = 'delivered'
GROUP BY DATE_FORMAT(order_purchase_timestamp, '%Y-%m-01')
ORDER BY month;

select order_purchase_timestamp from order_revenue;

-- Revenue by customer state
SELECT
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS num_orders,
    SUM(oi.price) AS revenue
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY revenue DESC;

-- Revenue by product category
SELECT
    p.product_category_name,
    COUNT(*) AS items_sold,
    SUM(oi.price) AS revenue
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
JOIN orders o ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY p.product_category_name
ORDER BY revenue DESC;

-- Repeat vs one-time customers (based on delivered orders)
WITH orders_per_customer AS (
    SELECT
        customer_id,
        COUNT(DISTINCT order_id) AS num_orders
    FROM orders
    WHERE order_status = 'delivered'
    GROUP BY customer_id
)
SELECT
    SUM(CASE WHEN num_orders = 1 THEN 1 ELSE 0 END) AS one_time_customers,
    SUM(CASE WHEN num_orders > 1 THEN 1 ELSE 0 END) AS repeat_customers,
    COUNT(*) AS total_customers,
    ROUND(
        100.0 * SUM(CASE WHEN num_orders > 1 THEN 1 ELSE 0 END) / NULLIF(COUNT(*),0),
        2
    ) AS repeat_rate_percent
FROM orders_per_customer;


# Traffic to Conversion Funnel
WITH 
all_customers AS (
    SELECT DISTINCT customer_id FROM customers
),
add_to_cart AS (
    SELECT DISTINCT o.customer_id
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
),
ordered AS (
    SELECT DISTINCT customer_id
    FROM orders
),
delivered AS (
    SELECT DISTINCT customer_id
    FROM orders
    WHERE order_status = 'delivered'
)

SELECT
    (SELECT COUNT(*) FROM all_customers) AS total_customers,
    (SELECT COUNT(*) FROM add_to_cart) AS customers_add_to_cart,
    (SELECT COUNT(*) FROM ordered) AS customers_ordered,
    (SELECT COUNT(*) FROM delivered) AS customers_delivered,

    ROUND(
        100.0 * (SELECT COUNT(*) FROM add_to_cart) /
        NULLIF((SELECT COUNT(*) FROM all_customers), 0), 2
    ) AS visit_to_cart_rate,

    ROUND(
        100.0 * (SELECT COUNT(*) FROM ordered) /
        NULLIF((SELECT COUNT(*) FROM add_to_cart), 0), 2
    ) AS cart_to_order_rate,

    ROUND(
        100.0 * (SELECT COUNT(*) FROM delivered) /
        NULLIF((SELECT COUNT(*) FROM ordered), 0), 2
    ) AS order_to_delivery_rate;


# Customer Cohort Analysis
-- Build a cohort for each customer
WITH first_order AS (
    SELECT
        customer_id,
        MIN(order_purchase_timestamp) AS first_order_ts
    FROM orders
    WHERE order_status IN ('delivered','shipped')
      AND order_purchase_timestamp IS NOT NULL
    GROUP BY customer_id
),
orders_with_cohort AS (
    SELECT
        o.customer_id,
        o.order_id,
        o.order_purchase_timestamp,
        DATE_FORMAT(f.first_order_ts, '%Y-%m-01') AS cohort_month,
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m-01') AS order_month
    FROM orders o
    JOIN first_order f ON f.customer_id = o.customer_id
    WHERE order_status IN ('delivered','shipped')
      AND o.order_purchase_timestamp IS NOT NULL
)
SELECT
    cohort_month,
    TIMESTAMPDIFF(
        MONTH,
        CAST(cohort_month AS DATE),
        CAST(order_month AS DATE)
    ) AS months_since_first_order,
    COUNT(DISTINCT customer_id) AS active_customers
FROM orders_with_cohort
GROUP BY cohort_month, months_since_first_order
ORDER BY cohort_month, months_since_first_order;


# Customer Lifetime Value (LTV)
-- LTV per customer
CREATE OR REPLACE VIEW customer_ltv AS
SELECT
    o.customer_id,
    SUM(oi.price) AS lifetime_value
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY o.customer_id;

SELECT * FROM customer_ltv ORDER BY lifetime_value DESC;

-- Average LTV by customer state
SELECT
    c.customer_state,
    AVG(l.lifetime_value) AS avg_ltv,
    COUNT(*) AS customers_in_state
FROM customer_ltv l
JOIN customers c ON c.customer_id = l.customer_id
GROUP BY c.customer_state
ORDER BY avg_ltv DESC;

# RFM Segmentation
-- fixed a snapshot date
SET @snapshot_date := (
    SELECT DATE(MAX(order_purchase_timestamp))
    FROM orders
    WHERE order_status = 'delivered'
);

SELECT @snapshot_date;

-- Compute R, F, M per customer
WITH customer_orders AS (
    SELECT
        o.customer_id,
        MAX(o.order_purchase_timestamp) AS last_order_ts,
        COUNT(DISTINCT o.order_id) AS frequency,
        SUM(oi.price) AS monetary
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY o.customer_id
),
rfm_raw AS (
    SELECT
        customer_id,
        DATEDIFF(@snapshot_date, DATE(last_order_ts)) AS recency,
        frequency,
        monetary
    FROM customer_orders
)
SELECT *
FROM rfm_raw
ORDER BY monetary DESC;

-- Turn R, F, M into scores (1–3)
WITH customer_orders AS (
    SELECT
        o.customer_id,
        MAX(o.order_purchase_timestamp) AS last_order_ts,
        COUNT(DISTINCT o.order_id) AS frequency,
        SUM(oi.price) AS monetary
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY o.customer_id
),
rfm_raw AS (
    SELECT
        customer_id,
        DATEDIFF(@snapshot_date, DATE(last_order_ts)) AS recency,
        frequency,
        monetary
    FROM customer_orders
),
rfm_scored AS (
    SELECT
        r.*,
        -- R: higher recency (older) = worse → score 1; lowest recency (most recent) → score 3
        NTILE(3) OVER (ORDER BY recency DESC) AS r_score,
        -- F: higher frequency is better → score 3
        NTILE(3) OVER (ORDER BY frequency ASC) AS f_score,
        -- M: higher spend is better → score 3
        NTILE(3) OVER (ORDER BY monetary ASC) AS m_score
    FROM rfm_raw r
)
SELECT *
FROM rfm_scored
ORDER BY m_score DESC, f_score DESC, r_score DESC;

-- Create segments (Champions, Loyal, At Risk, Lost, Others)
WITH customer_orders AS (
    SELECT
        o.customer_id,
        MAX(o.order_purchase_timestamp) AS last_order_ts,
        COUNT(DISTINCT o.order_id) AS frequency,
        SUM(oi.price) AS monetary
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY o.customer_id
),
rfm_raw AS (
    SELECT
        customer_id,
        DATEDIFF(@snapshot_date, DATE(last_order_ts)) AS recency,
        frequency,
        monetary
    FROM customer_orders
),
rfm_scored AS (
    SELECT
        r.*,
        NTILE(3) OVER (ORDER BY recency DESC) AS r_score,
        NTILE(3) OVER (ORDER BY frequency ASC) AS f_score,
        NTILE(3) OVER (ORDER BY monetary ASC) AS m_score
    FROM rfm_raw r
)
SELECT
    customer_id,
    recency,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    CASE
        WHEN r_score = 3 AND f_score = 3 AND m_score = 3 THEN 'Champions'
        WHEN r_score >= 2 AND f_score >= 2 AND m_score >= 2 THEN 'Loyal'
        WHEN r_score = 1 AND f_score >= 2 THEN 'At Risk'
        WHEN r_score = 1 AND f_score = 1 THEN 'Lost'
        ELSE 'Others'
    END AS segment
FROM rfm_scored
ORDER BY segment, monetary DESC;


# Product Affinity (Simple Co-Purchase Counts)

WITH basket AS (
    SELECT DISTINCT order_id, product_id
    FROM order_items
),
pairs AS (
    SELECT
        b1.product_id AS product_a,
        b2.product_id AS product_b,
        COUNT(*) AS together_count
    FROM basket b1
    JOIN basket b2
      ON b1.order_id = b2.order_id
     AND b1.product_id < b2.product_id
    GROUP BY b1.product_id, b2.product_id
)
SELECT
    p1.product_id AS product_a,
    p1.product_category_name AS product_a_category,
    p2.product_id AS product_b,
    p2.product_category_name AS product_b_category,
    together_count
FROM pairs
JOIN products p1 ON p1.product_id = pairs.product_a
JOIN products p2 ON p2.product_id = pairs.product_b
ORDER BY together_count DESC
LIMIT 20;
