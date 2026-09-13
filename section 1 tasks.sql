USE bikestores;
SELECT*FROM sales.customers;
SELECT*FROM sales.customers
where customer_id > 1000;
select*from sales.customers
where state = 'NY';
SELECT *
FROM sales.orders
WHERE YEAR(order_date) = 2017;
SELECT *
FROM production.products
WHERE product_name LIKE '%Trek%';
SELECT * FROM sales.customers WHERE customer_id BETWEEN 500 AND 1500;
SELECT DISTINCT city
FROM sales.customers;
SELECT *
FROM sales.orders
WHERE shipped_date IS NULL;























