-- self join 
SELECT
    s.first_name + ' ' + s.last_name AS staff_name,
    m.first_name + ' ' + m.last_name AS manager_name
FROM sales.staffs AS s
LEFT JOIN sales.staffs AS m
    ON s.manager_id = m.staff_id;
    SELECT
    p1.product_name AS product_1,
    p2.product_name AS product_2,
    b.brand_name
FROM production.products AS p1
JOIN production.products AS p2
    ON p1.brand_id = p2.brand_id
    AND p1.list_price = p2.list_price
    AND p1.product_id < p2.product_id
JOIN production.brands AS b
    ON p1.brand_id = b.brand_id;
-- cross join 
SELECT
    b.brand_name,
    c.category_name
FROM production.brands AS b
CROSS JOIN production.categories AS c;
SELECT
    b.brand_name,
    c.category_name
FROM production.brands AS b
CROSS JOIN production.categories AS c
LEFT JOIN production.products AS p
    ON p.brand_id = b.brand_id
    AND p.category_id = c.category_id
WHERE p.product_id IS NULL;

-- right join 

SELECT
    b.brand_name,
    p.product_name
FROM production.products AS p
RIGHT JOIN production.brands AS b
    ON p.brand_id = b.brand_id;
SELECT
    s.store_name,
    o.order_id,
    o.order_date,
    o.order_status
FROM sales.orders AS o
RIGHT JOIN sales.stores AS s
    ON o.store_id = s.store_id;
   -- Left Anti Join
   SELECT
    c.customer_id,
    c.first_name,
    c.last_name
FROM sales.customers AS c
LEFT JOIN sales.orders AS o
    ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL;
SELECT
    product_id,
    product_name
FROM production.products
WHERE product_id NOT IN (
    SELECT product_id
    FROM production.stocks
    WHERE quantity > 0
);
SELECT
    p.product_id,
    p.product_name
FROM production.products AS p
LEFT JOIN sales.order_items AS oi
    ON p.product_id = oi.product_id
WHERE oi.product_id IS NULL;
SELECT
    c.category_id,
    c.category_name
FROM production.categories AS c
WHERE NOT EXISTS (
    SELECT 1
    FROM production.products AS p
    WHERE p.category_id = c.category_id
      AND p.list_price > 2000
);
SELECT
    c.customer_id,
    c.first_name,
    c.last_name
FROM sales.customers AS c
WHERE EXISTS (
    SELECT 1
    FROM sales.orders AS o
    WHERE o.customer_id = c.customer_id
)
AND NOT EXISTS (
    SELECT 1
    FROM sales.orders AS o
    JOIN sales.order_items AS oi
        ON o.order_id = oi.order_id
    JOIN production.products AS p
        ON oi.product_id = p.product_id
    JOIN production.brands AS b
        ON p.brand_id = b.brand_id
    WHERE o.customer_id = c.customer_id
      AND b.brand_name = 'Trek'
);
