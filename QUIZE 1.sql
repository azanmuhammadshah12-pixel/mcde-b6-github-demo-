-- (Task 1 — Build the Sales Detail Dataset) --

-- Management needs a detailed sales dataset for analysis. Return one row per order item containing:
-- order_id and order_date
-- customer full name
-- store name
-- staff full name
-- product name
-- category name
-- brand name
-- quantity, list_price, discount
-- calculated net_line_revenue
-- Include only completed orders (order_status = 4). Sort the result from newest order to oldest.
USE bikestores;

SELECT
    o.order_id,
    o.order_date,

    CONCAT(c.first_name, ' ', c.last_name) AS customer_full_name,
    s.store_name,
    CONCAT(st.first_name, ' ', st.last_name) AS staff_full_name,

    p.product_name,
    cat.category_name,
    b.brand_name,

    oi.quantity,
    oi.list_price,
    oi.discount,

    oi.quantity * oi.list_price * (1 - oi.discount) AS net_line_revenue

FROM sales.orders o

INNER JOIN sales.customers c
    ON o.customer_id = c.customer_id

INNER JOIN sales.stores s
    ON o.store_id = s.store_id

INNER JOIN sales.staffs st
    ON o.staff_id = st.staff_id

INNER JOIN sales.order_items oi
    ON o.order_id = oi.order_id

INNER JOIN production.products p
    ON oi.product_id = p.product_id

INNER JOIN production.categories cat
    ON p.category_id = cat.category_id

INNER JOIN production.brands b
    ON p.brand_id = b.brand_id

WHERE o.order_status = 4

ORDER BY o.order_date DESC;

------- (Task 2 — Store Performance Summary) -------

-- Create a store-level performance report for completed orders showing:
-- store name
-- number of distinct orders
-- total units sold
-- total net revenue
-- average order value
-- Return one row per store and order the stores from highest to lowest total net revenue.


SELECT
    s.store_name,
    COUNT(DISTINCT o.order_id) AS number_of_orders,
    SUM(oi.quantity) AS total_units_sold,
    SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_net_revenue,
    SUM(oi.quantity * oi.list_price * (1 - oi.discount))
        / COUNT(DISTINCT o.order_id) AS average_order_value

FROM sales.orders o

INNER JOIN sales.stores s
    ON o.store_id = s.store_id

INNER JOIN sales.order_items oi
    ON o.order_id = oi.order_id

WHERE o.order_status = 4

GROUP BY s.store_name

ORDER BY total_net_revenue DESC; 

--------- (Task 3 — High-Value Customers) ---------

-- Management wants to identify high-value customers. Return customers whose total completed-order spending is
-- greater than the average total spending of customers who have completed orders.
SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_spending
FROM sales.customers c
INNER JOIN sales.orders o
    ON c.customer_id = o.customer_id
INNER JOIN sales.order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 4
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name
HAVING SUM(oi.quantity * oi.list_price * (1 - oi.discount)) >
(
    SELECT AVG(customer_total)
    FROM
    (
        SELECT
            o.customer_id,
            SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS customer_total
        FROM sales.orders o
        INNER JOIN sales.order_items oi
            ON o.order_id = oi.order_id
        WHERE o.order_status = 4
        GROUP BY o.customer_id
    ) AS customer_spending
);

----- Q:2

-- Show customer_id, customer name, completed order count, and total spending. Order the result by total spending descending.
SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    COUNT(DISTINCT o.order_id) AS completed_order_count,
    SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_spending
FROM sales.customers c
INNER JOIN sales.orders o
    ON c.customer_id = o.customer_id
INNER JOIN sales.order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 4
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name
ORDER BY total_spending DESC;

----- Task 4 — Inventory Risk Report ---

-- Operations wants to identify inventory risk. Return products where the stock quantity is below 5 in at least one store.
SELECT DISTINCT
    p.product_id,
    p.product_name
FROM production.products p
INNER JOIN production.stocks s
    ON p.product_id = s.product_id
WHERE s.quantity < 5; 

 ---- Q:2

 -- Show product name, store name, current quantity, category name, and brand name. 
 -- Products with zero stock should appear first, followed by the lowest remaining quantities.
SELECT
    p.product_name,
    s.store_name,
    st.quantity AS current_quantity,
    c.category_name,
    b.brand_name
FROM production.stocks st
INNER JOIN production.products p
    ON st.product_id = p.product_id
INNER JOIN sales.stores s
    ON st.store_id = s.store_id
INNER JOIN production.categories c
    ON p.category_id = c.category_id
INNER JOIN production.brands b
    ON p.brand_id = b.brand_id
ORDER BY
    st.quantity ASC;

--- Task 5 — Top Products Within Each Category ---
USE bikestores;

WITH product_revenue AS
(
    SELECT
        c.category_name,
        p.product_id,
        p.product_name,
        SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_net_revenue
    FROM production.products p

    INNER JOIN production.categories c
        ON p.category_id = c.category_id

    INNER JOIN sales.order_items oi
        ON p.product_id = oi.product_id

    INNER JOIN sales.orders o
        ON oi.order_id = o.order_id

    WHERE o.order_status = 4

    GROUP BY
        c.category_name,
        p.product_id,
        p.product_name
),

ranked_products AS
(
    SELECT
        category_name,
        product_id,
        product_name,
        total_net_revenue,
        ROW_NUMBER() OVER (
            PARTITION BY category_name
            ORDER BY total_net_revenue DESC
        ) AS product_rank
    FROM product_revenue
)

SELECT
    category_name,
    product_id,
    product_name,
    total_net_revenue,
    product_rank
FROM ranked_products
WHERE product_rank <= 3
ORDER BY
    category_name,
    product_rank;

-- Q:2 

-- Return category name, product name, total units sold, total net revenue, and the product's position within its category.
-- Tied products must receive the same position and the next position should not contain gaps.

WITH product_sales AS
(
    SELECT
        c.category_name,
        p.product_name,
        SUM(oi.quantity) AS total_units_sold,
        SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_net_revenue
    FROM production.products p

    INNER JOIN production.categories c
        ON p.category_id = c.category_id

    INNER JOIN sales.order_items oi
        ON p.product_id = oi.product_id

    INNER JOIN sales.orders o
        ON oi.order_id = o.order_id

    WHERE o.order_status = 4

    GROUP BY
        c.category_name,
        p.product_name
)

SELECT
    category_name,
    product_name,
    total_units_sold,
    total_net_revenue,

    DENSE_RANK() OVER (
        PARTITION BY category_name
        ORDER BY total_net_revenue DESC
    ) AS product_position

FROM product_sales

ORDER BY
    category_name,
    product_position; 

-- Task 6 — Monthly Sales Trend --

-- Create a monthly sales trend for completed orders.
-- For each calendar month return:
-- year
-- month
-- total net revenue
-- previous month's total net revenue
-- revenue change from the previous month
-- The first month may have NULL for the previous-month comparison. Sort chronologically.

USE bikestores;

WITH monthly_sales AS
(
    SELECT
        YEAR(o.order_date) AS year,
        MONTH(o.order_date) AS month,

        SUM(
            oi.quantity * oi.list_price * (1 - oi.discount)
        ) AS total_net_revenue

    FROM sales.orders o

    INNER JOIN sales.order_items oi
        ON o.order_id = oi.order_id

    WHERE o.order_status = 4

    GROUP BY
        YEAR(o.order_date),
        MONTH(o.order_date)
),

monthly_comparison AS
(
    SELECT
        year,
        month,
        total_net_revenue,

        LAG(total_net_revenue) OVER (
            ORDER BY year, month
        ) AS previous_month_revenue

    FROM monthly_sales
)

SELECT
    year,
    month,
    total_net_revenue,
    previous_month_revenue,

    total_net_revenue - previous_month_revenue
        AS revenue_change

FROM monthly_comparison

ORDER BY
    year,
    month;

-- Task 7 — Reusable Reporting View --

-- Create a view named sales.vw_customer_sales_summary that returns one row per customer and includes:
-- customer_id
-- customer full name
-- total number of completed orders
-- total units purchased
-- total net revenue
-- most recent completed order date
-- Customers with no completed orders must still be represented where possible, with appropriate zero/NULL values.
USE bikestores;

CREATE VIEW sales.vw_customer_sales_summary
AS
SELECT
    c.customer_id,

    CONCAT(c.first_name, ' ', c.last_name) AS customer_full_name,

    COUNT(DISTINCT o.order_id) AS total_completed_orders,

    COALESCE(SUM(oi.quantity), 0) AS total_units_purchased,

    COALESCE(
        SUM(oi.quantity * oi.list_price * (1 - oi.discount)),
        0
    ) AS total_net_revenue,

    MAX(o.order_date) AS most_recent_completed_order_date

FROM sales.customers c

LEFT JOIN sales.orders o
    ON c.customer_id = o.customer_id
    AND o.order_status = 4

LEFT JOIN sales.order_items oi
    ON o.order_id = oi.order_id

GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name;

-- Task 8 — Safe Data Modification --

-- A customer with customer_id = 1 has requested that their phone number be changed to '(999) 555-0101'.
 
USE bikestores;

BEGIN TRANSACTION;

UPDATE sales.customers
SET phone = '(999) 555-0101'
WHERE customer_id = 1;

SELECT
    customer_id,
    first_name,
    last_name,
    phone
FROM sales.customers
WHERE customer_id = 1;
ROLLBACK TRANSACTION;

-- Task 9 — Store Sales Procedure --
-- Create a stored procedure named sales.usp_store_sales_report with these input parameters:
-- @store_id
-- @start_date
-- @end_date

-- The procedure should return completed-order sales for the requested store and date range, grouped by product. Return product name, total units sold, and total net revenue, ordered by revenue descending.

-- Add appropriate error handling for invalid date ranges where @start_date is later than @end_date.
GO

CREATE PROCEDURE sales.usp_store_sales_report
    @store_id INT,
    @start_date DATE,
    @end_date DATE
AS
BEGIN

    IF @start_date > @end_date
    BEGIN
        THROW 50001, 'Start date cannot be later than end date.', 1;
    END;

    SELECT
        p.product_name,
        SUM(oi.quantity) AS total_units_sold,
        SUM(
            oi.quantity * oi.list_price * (1 - oi.discount)
        ) AS total_net_revenue
    FROM sales.orders o
    INNER JOIN sales.order_items oi
        ON o.order_id = oi.order_id
    INNER JOIN production.products p
        ON oi.product_id = p.product_id
    WHERE o.store_id = @store_id
      AND o.order_status = 4
      AND o.order_date BETWEEN @start_date AND @end_date
    GROUP BY
        p.product_name
    ORDER BY
        total_net_revenue DESC;

END;
GO
EXEC sales.usp_store_sales_report
    @store_id = 1,
    @start_date = '2018-01-01',
    @end_date = '2018-12-31';

-- Task 10 — Management Insight Query (
-- Write one additional SQL query that you believe would provide useful insight to BikeStores management using at least three tables.
-- Below the query, add a SQL comment of no more than three lines explaining:
-- 1. the business question,
-- 2. what the result measures, and
-- 3. why management should care about it.
SELECT
    s.store_name,
    c.category_name,
    SUM(oi.quantity) AS total_units_sold,
    SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_net_revenue
FROM sales.orders o
INNER JOIN sales.order_items oi
    ON o.order_id = oi.order_id
INNER JOIN sales.stores s
    ON o.store_id = s.store_id
INNER JOIN production.products p
    ON oi.product_id = p.product_id
INNER JOIN production.categories c
    ON p.category_id = c.category_id
WHERE o.order_status = 4
GROUP BY
    s.store_name,
    c.category_name
ORDER BY total_net_revenue DESC;

-- Business question: Which stores and product categories generate the most sales?
-- Measures total units sold and net revenue for completed orders.
-- Management can use this to identify strong-performing stores and categories.
