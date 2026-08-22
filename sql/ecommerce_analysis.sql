-- E-Commerce Customer & Sales Analysis (SQLite)

-- KPI
SELECT COUNT(*) total_orders,
       ROUND(SUM(order_total),2) total_revenue,
       ROUND(AVG(order_total),2) average_order_value
FROM orders WHERE status='Delivered';

-- Monthly revenue
SELECT strftime('%Y-%m', order_date) month,
       ROUND(SUM(order_total),2) revenue
FROM orders WHERE status='Delivered'
GROUP BY 1 ORDER BY 1;

-- Category revenue
SELECT p.category, ROUND(SUM(oi.line_revenue),2) revenue
FROM order_items oi
JOIN orders o ON o.order_id=oi.order_id
JOIN products p ON p.product_id=oi.product_id
WHERE o.status='Delivered'
GROUP BY p.category ORDER BY revenue DESC;

-- Top-selling products
SELECT p.product_name, SUM(oi.quantity) units,
       ROUND(SUM(oi.line_revenue),2) revenue
FROM order_items oi
JOIN orders o ON o.order_id=oi.order_id
JOIN products p ON p.product_id=oi.product_id
WHERE o.status='Delivered'
GROUP BY p.product_id ORDER BY revenue DESC LIMIT 10;

-- Top customers by revenue
SELECT c.customer_id, c.customer_name,
       COUNT(DISTINCT o.order_id) orders,
       ROUND(SUM(o.order_total),2) revenue
FROM customers c JOIN orders o ON c.customer_id=o.customer_id
WHERE o.status='Delivered'
GROUP BY c.customer_id ORDER BY revenue DESC LIMIT 10;

-- Repeat vs one-time customers (CTE + CASE)
WITH customer_orders AS (
  SELECT customer_id, COUNT(*) order_count, SUM(order_total) revenue
  FROM orders WHERE status='Delivered'
  GROUP BY customer_id
)
SELECT CASE WHEN order_count=1 THEN 'One-time' ELSE 'Repeat' END customer_type,
       COUNT(*) customers,
       ROUND(SUM(revenue),2) revenue
FROM customer_orders GROUP BY 1;

-- Purchase frequency & spending
SELECT customer_id, COUNT(*) purchase_frequency,
       ROUND(AVG(order_total),2) avg_spend,
       ROUND(SUM(order_total),2) total_spend
FROM orders WHERE status='Delivered'
GROUP BY customer_id ORDER BY total_spend DESC;

-- New vs returning orders using window function
WITH ranked AS (
 SELECT order_id, customer_id, order_date, order_total,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date, order_id) rn
 FROM orders WHERE status='Delivered'
)
SELECT CASE WHEN rn=1 THEN 'New' ELSE 'Returning' END customer_status,
       COUNT(*) orders, ROUND(SUM(order_total),2) revenue
FROM ranked GROUP BY 1;

-- Revenue contribution and cumulative share
WITH customer_rev AS (
 SELECT customer_id, SUM(order_total) revenue
 FROM orders WHERE status='Delivered'
 GROUP BY customer_id
), ranked AS (
 SELECT customer_id, revenue,
        SUM(revenue) OVER () total_revenue,
        SUM(revenue) OVER (ORDER BY revenue DESC ROWS UNBOUNDED PRECEDING) cumulative_revenue
 FROM customer_rev
)
SELECT customer_id, ROUND(revenue,2) revenue,
       ROUND(100.0*revenue/total_revenue,2) revenue_share_pct,
       ROUND(100.0*cumulative_revenue/total_revenue,2) cumulative_share_pct
FROM ranked ORDER BY revenue DESC;

-- Basic segmentation
WITH s AS (
 SELECT customer_id,
        COUNT(*) frequency,
        SUM(order_total) monetary
 FROM orders WHERE status='Delivered'
 GROUP BY customer_id
)
SELECT customer_id, frequency, ROUND(monetary,2) monetary,
 CASE
   WHEN frequency >= 5 AND monetary >= 15000 THEN 'Champions'
   WHEN frequency >= 3 AND monetary >= 7000 THEN 'Loyal'
   WHEN frequency = 1 THEN 'One-time'
   ELSE 'Regular'
 END segment
FROM s ORDER BY monetary DESC;

-- Subquery example: customers above average customer revenue
SELECT *
FROM (
  SELECT customer_id, SUM(order_total) customer_revenue
  FROM orders WHERE status='Delivered'
  GROUP BY customer_id
) x
WHERE customer_revenue > (
  SELECT AVG(customer_revenue)
  FROM (
    SELECT SUM(order_total) customer_revenue
    FROM orders WHERE status='Delivered'
    GROUP BY customer_id
  )
);
