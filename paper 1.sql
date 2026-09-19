
-- task number # 6 

SELECT
    o.order_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    s.store_name,
    CONCAT(st.first_name, ' ', st.last_name) AS staff_name
FROM sales.orders AS o
JOIN sales.customers AS c
    ON o.customer_id = c.customer_id
JOIN sales.stores AS s
    ON o.store_id = s.store_id
JOIN sales.staffs AS st
    ON o.staff_id = st.staff_id;

    SELECT
    p.product_name,
    b.brand_name,
    c.category_name
FROM production.products AS p
LEFT JOIN production.brands AS b
    ON p.brand_id = b.brand_id
LEFT JOIN production.categories AS c
    ON p.category_id = c.category_id;


SELECT
    c.first_name,
    c.last_name,
    c.city,
    c.email
FROM sales.customers AS c
LEFT JOIN sales.orders AS o
    ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL;
-- group by 
SELECT
    o.store_id,
    SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_revenue
FROM sales.orders AS o
JOIN sales.order_items AS oi
    ON o.order_id = oi.order_id
GROUP BY o.store_id
ORDER BY total_revenue DESC;

SELECT
    brand_id,
    COUNT(*) AS total_products,
    AVG(list_price) AS average_price,
    MAX(list_price) AS highest_price
FROM production.products
GROUP BY brand_id
HAVING COUNT(*) > 5;

SELECT
    MONTH(o.order_date) AS order_month,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_revenue
FROM sales.orders AS o
JOIN sales.order_items AS oi
    ON o.order_id = oi.order_id
WHERE YEAR(o.order_date) = 2017
GROUP BY MONTH(o.order_date)
ORDER BY MONTH(o.order_date);

-- sub query 
SELECT
    p.product_name,
    p.list_price,
    p.category_id
FROM production.products AS p
WHERE p.list_price > (
    SELECT AVG(p2.list_price)
    FROM production.products AS p2
    WHERE p2.category_id = p.category_id
);

SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    COUNT(o.order_id) AS total_orders
FROM sales.customers AS c
JOIN sales.orders AS o
    ON c.customer_id = o.customer_id
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name
HAVING COUNT(o.order_id) > (
    SELECT AVG(order_count)
    FROM (
        SELECT
            customer_id,
            COUNT(*) AS order_count
        FROM sales.orders
        GROUP BY customer_id
    ) AS customer_orders
);

-- CTEs 

WITH customer_spend AS (
    SELECT
        c.customer_id,
        c.first_name,
        c.last_name,
        SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_spend
    FROM sales.customers AS c
    JOIN sales.orders AS o
        ON c.customer_id = o.customer_id
    JOIN sales.order_items AS oi
        ON o.order_id = oi.order_id
    GROUP BY
        c.customer_id,
        c.first_name,
        c.last_name
),

customer_labels AS (
    SELECT
        customer_id,
        first_name,
        last_name,
        total_spend,
        CASE
            WHEN total_spend > (SELECT AVG(total_spend) FROM customer_spend)
                THEN 'High'
            ELSE 'Regular'
        END AS spend_label
    FROM customer_spend
)

SELECT TOP 10
    customer_id,
    first_name,
    last_name,
    total_spend,
    spend_label,
    RANK() OVER (ORDER BY total_spend DESC) AS spend_rank
FROM customer_labels
ORDER BY total_spend DESC;


WITH product_sales AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category_id,
        SUM(oi.quantity) AS total_sold
    FROM production.products AS p
    JOIN sales.order_items AS oi
        ON p.product_id = oi.product_id
    GROUP BY
        p.product_id,
        p.product_name,
        p.category_id
),

best_products AS (
    SELECT
        product_id,
        product_name,
        category_id,
        total_sold,
        RANK() OVER (
            PARTITION BY category_id
            ORDER BY total_sold DESC
        ) AS product_rank
    FROM product_sales
),

product_stock AS (
    SELECT
        product_id,
        SUM(quantity) AS total_stock
    FROM production.stocks
    GROUP BY product_id
)

SELECT
    bp.category_id,
    bp.product_name,
    bp.total_sold,
    COALESCE(ps.total_stock, 0) AS total_stock
FROM best_products AS bp
LEFT JOIN product_stock AS ps
    ON bp.product_id = ps.product_id
WHERE bp.product_rank = 1;