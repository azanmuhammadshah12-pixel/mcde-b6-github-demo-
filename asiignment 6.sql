WITH store_counts AS
(
    SELECT
        store_id,
        COUNT(*) AS order_count
    FROM sales.orders
    GROUP BY store_id
)
SELECT
    AVG(order_count) AS avg_orders
FROM store_counts;

SELECT
    product_id,
    product_name,
    category_id,
    list_price,

    ROW_NUMBER() OVER (
        ORDER BY list_price DESC
    ) AS overall_row_number,

    ROW_NUMBER() OVER (
        PARTITION BY category_id
        ORDER BY list_price DESC
    ) AS category_row_number

FROM production.products;

WITH cte_high_value_products AS
(
    SELECT
        product_id,
        product_name,
        category_id,
        list_price
    FROM production.products
    WHERE list_price > 2000
)
SELECT
    h.product_id,
    h.product_name,
    h.list_price,
    c.category_name
FROM cte_high_value_products h
JOIN production.categories c
    ON h.category_id = c.category_id
WHERE c.category_name = 'Mountain Bikes';



WITH customer_orders AS
(
    SELECT
        customer_id,
        COUNT(*) AS order_count
    FROM sales.orders
    GROUP BY customer_id
),

customer_revenue AS
(
    SELECT
        o.customer_id,
        SUM(i.quantity * i.list_price * (1 - i.discount)) AS total_revenue
    FROM sales.orders o
    JOIN sales.order_items i
        ON o.order_id = i.order_id
    GROUP BY o.customer_id
)

SELECT
    o.customer_id,
    o.order_count,
    r.total_revenue
FROM customer_orders o
JOIN customer_revenue r
    ON o.customer_id = r.customer_id;

WITH numbers AS
(
    SELECT
        1 AS n,
        1 * 1 AS square

    UNION ALL

    SELECT
        n + 1,
        (n + 1) * (n + 1)
    FROM numbers
    WHERE n < 10
)
SELECT *
FROM numbers
OPTION (MAXRECURSION 10);

WITH org_chart AS
(
   
    SELECT
        staff_id,
        first_name,
        manager_id,
        CAST(NULL AS VARCHAR(100)) AS manager_name,
        0 AS level
    FROM sales.staffs
    WHERE manager_id IS NULL

    UNION ALL

    
    SELECT
        s.staff_id,
        s.first_name,
        s.manager_id,
        o.first_name AS manager_name,
        o.level + 1 AS level
    FROM sales.staffs s
    JOIN org_chart o
        ON s.manager_id = o.staff_id
)
SELECT
    staff_id,
    first_name,
    manager_name,
    level
FROM org_chart
ORDER BY level, staff_id;

WITH customer_orders AS
(
    SELECT
        customer_id,
        COUNT(*) AS order_count
    FROM sales.orders
    GROUP BY customer_id
)
SELECT *
FROM customer_orders;

