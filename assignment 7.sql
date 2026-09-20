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

SELECT
    product_id,
    product_name,
    category_id,
    list_price,

    RANK() OVER (
        PARTITION BY category_id
        ORDER BY list_price DESC
    ) AS price_rank,

    DENSE_RANK() OVER (
        PARTITION BY category_id
        ORDER BY list_price DESC
    ) AS dense_price_rank

FROM production.products;

WITH monthly_revenue AS
(
    SELECT
        o.store_id,
        YEAR(o.order_date) AS order_year,
        MONTH(o.order_date) AS order_month,
        SUM(i.quantity * i.list_price * (1 - i.discount)) AS revenue
    FROM sales.orders o
    JOIN sales.order_items i
        ON o.order_id = i.order_id
    GROUP BY
        o.store_id,
        YEAR(o.order_date),
        MONTH(o.order_date)
)
SELECT
    store_id,
    order_year,
    order_month,
    revenue AS current_month_revenue,

    LAG(revenue) OVER (
        PARTITION BY store_id
        ORDER BY order_year, order_month
    ) AS previous_month_revenue,

    revenue - LAG(revenue) OVER (
        PARTITION BY store_id
        ORDER BY order_year, order_month
    ) AS revenue_difference

FROM monthly_revenue
ORDER BY store_id, order_year, order_month;

WITH monthly_revenue AS
(
    SELECT
        o.store_id,
        YEAR(o.order_date) AS order_year,
        MONTH(o.order_date) AS order_month,
        SUM(i.quantity * i.list_price * (1 - i.discount)) AS revenue
    FROM sales.orders o
    JOIN sales.order_items i
        ON o.order_id = i.order_id
    GROUP BY
        o.store_id,
        YEAR(o.order_date),
        MONTH(o.order_date)
)
SELECT
    store_id,
    order_year,
    order_month,
    revenue AS current_month_revenue,

    LAG(revenue) OVER (
        PARTITION BY store_id
        ORDER BY order_year, order_month
    ) AS previous_month_revenue,

    revenue - LAG(revenue) OVER (
        PARTITION BY store_id
        ORDER BY order_year, order_month
    ) AS revenue_difference

FROM monthly_revenue
ORDER BY store_id, order_year, order_month;

SELECT
    o.order_id,
    o.order_date,
    SUM(i.quantity * i.list_price * (1 - i.discount)) AS order_revenue,

    SUM(SUM(i.quantity * i.list_price * (1 - i.discount))) OVER (
        ORDER BY o.order_date, o.order_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total_revenue

FROM sales.orders o
JOIN sales.order_items i
    ON o.order_id = i.order_id

GROUP BY
    o.order_id,
    o.order_date;

    SELECT
    product_id,
    product_name,
    category_id,
    list_price,

    FIRST_VALUE(list_price) OVER (
        PARTITION BY category_id
        ORDER BY list_price
    ) AS first_price,

    LAST_VALUE(list_price) OVER (
        PARTITION BY category_id
        ORDER BY list_price
        RANGE BETWEEN UNBOUNDED PRECEDING
        AND UNBOUNDED FOLLOWING
    ) AS last_price

FROM production.products;