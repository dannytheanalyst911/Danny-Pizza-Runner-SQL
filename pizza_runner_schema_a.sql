CREATE TABLE runners (
  runner_id INTEGER,
  registration_date DATE
);
INSERT INTO runners
  (runner_id, registration_date)
VALUES
  (1, '2021-01-01'),
  (2, '2021-01-03'),
  (3, '2021-01-08'),
  (4, '2021-01-15');


DROP TABLE IF EXISTS customer_orders;
CREATE TABLE customer_orders (
  order_id INTEGER,
  customer_id INTEGER,
  pizza_id INTEGER,
  exclusions VARCHAR(4),
  extras VARCHAR(4),
  order_time TIMESTAMP
);

INSERT INTO customer_orders
  (order_id, customer_id, pizza_id, exclusions, extras, order_time)
VALUES
  ('1', '101', '1', '', '', '2020-01-01 18:05:02'),
  ('2', '101', '1', '', '', '2020-01-01 19:00:52'),
  ('3', '102', '1', '', '', '2020-01-02 23:51:23'),
  ('3', '102', '2', '', NULL, '2020-01-02 23:51:23'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '2', '4', '', '2020-01-04 13:23:46'),
  ('5', '104', '1', 'null', '1', '2020-01-08 21:00:29'),
  ('6', '101', '2', 'null', 'null', '2020-01-08 21:03:13'),
  ('7', '105', '2', 'null', '1', '2020-01-08 21:20:29'),
  ('8', '102', '1', 'null', 'null', '2020-01-09 23:54:33'),
  ('9', '103', '1', '4', '1, 5', '2020-01-10 11:22:59'),
  ('10', '104', '1', 'null', 'null', '2020-01-11 18:34:49'),
  ('10', '104', '1', '2, 6', '1, 4', '2020-01-11 18:34:49');


DROP TABLE IF EXISTS runner_orders;
CREATE TABLE runner_orders (
  order_id INTEGER,
  runner_id INTEGER,
  pickup_time VARCHAR(19),
  distance VARCHAR(7),
  duration VARCHAR(10),
  cancellation VARCHAR(23)
);

INSERT INTO runner_orders
  (order_id, runner_id, pickup_time, distance, duration, cancellation)
VALUES
  ('1', '1', '2020-01-01 18:15:34', '20km', '32 minutes', ''),
  ('2', '1', '2020-01-01 19:10:54', '20km', '27 minutes', ''),
  ('3', '1', '2020-01-03 00:12:37', '13.4km', '20 mins', NULL),
  ('4', '2', '2020-01-04 13:53:03', '23.4', '40', NULL),
  ('5', '3', '2020-01-08 21:10:57', '10', '15', NULL),
  ('6', '3', 'null', 'null', 'null', 'Restaurant Cancellation'),
  ('7', '2', '2020-01-08 21:30:45', '25km', '25mins', 'null'),
  ('8', '2', '2020-01-10 00:15:02', '23.4 km', '15 minute', 'null'),
  ('9', '2', 'null', 'null', 'null', 'Customer Cancellation'),
  ('10', '1', '2020-01-11 18:50:20', '10km', '10minutes', 'null');


DROP TABLE IF EXISTS pizza_names;
CREATE TABLE pizza_names (
  pizza_id INTEGER,
  pizza_name TEXT
);
INSERT INTO pizza_names
  (pizza_id, pizza_name)
VALUES
  (1, 'Meatlovers'),
  (2, 'Vegetarian');


DROP TABLE IF EXISTS pizza_recipes;
CREATE TABLE pizza_recipes (
  pizza_id INTEGER,
  toppings TEXT
);
INSERT INTO pizza_recipes
  (pizza_id, toppings)
VALUES
  (1, '1, 2, 3, 4, 5, 6, 8, 10'),
  (2, '4, 6, 7, 9, 11, 12');


DROP TABLE IF EXISTS pizza_toppings;
CREATE TABLE pizza_toppings (
  topping_id INTEGER,
  topping_name TEXT
);
INSERT INTO pizza_toppings
  (topping_id, topping_namecustomer_orderscustomer_orders)
VALUES
  (1, 'Bacon'),
  (2, 'BBQ Sauce'),
  (3, 'Beef'),
  (4, 'Cheese'),
  (5, 'Chicken'),
  (6, 'Mushrooms'),
  (7, 'Onions'),
  (8, 'Pepperoni'),
  (9, 'Peppers'),
  (10, 'Salami'),
  (11, 'Tomatoes'),
  (12, 'Tomato Sauce');
  
-- A. Pizza Metrics
-- How many pizzas were ordered?

SELECT
	COUNT(pizza_id) as pizzas_ordered
FROM customer_orders;

-- How many unique customer orders were made?

SELECT
	COUNT(DISTINCT(order_id)) as unique_orders
FROM customer_orders;

-- How many successful orders were delivered by each runner?

SELECT
	runner_id,
    COUNT(order_id) as deli_ok
FROM runner_orders
WHERE distance != 0
GROUP BY runner_id;

-- can not use IS NOT NULL because the 'null' is also a value, it different from NULL.

-- How many of each type of pizza was delivered?

SELECT
	pizza_name,
    COUNT(pizza_name) as cnt
FROM runner_orders r 
JOIN customer_orders c 
	ON r.order_id=c.order_id
JOIN pizza_names p 
	ON c.pizza_id=p.pizza_id
WHERE r.distance != 0
GROUP BY pizza_name;

-- How many Vegetarian and Meatlovers were ordered by each customer?

SELECT
	customer_id,
    pizza_name,
	COUNT(customer_id) as cnt
FROM customer_orders c
JOIN pizza_names p
	ON c.pizza_id=p.pizza_id
GROUP BY customer_id, pizza_name
ORDER BY customer_id, pizza_name;

-- What was the maximum number of pizzas delivered in a single order?

SELECT 
    c.order_id, COUNT(pizza_id) AS cnt
FROM
    customer_orders c
        JOIN
    runner_orders r ON c.order_id = r.order_id
WHERE
    distance != 0
GROUP BY c.order_id
ORDER BY cnt DESC
LIMIT 1;

-- For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
WITH change_table AS
(
	SELECT 
		c.customer_id,
		c.order_id,
		CASE 
			WHEN c.exclusions != 0 OR c.extras != 0 THEN 1
			ELSE 0
		END AS changes
	FROM
		customer_orders c
	JOIN
		runner_orders r 
		ON c.order_id = r.order_id
	WHERE distance != 0
)
SELECT 
	customer_id,
	sum(changes) AS pz_changed,
    sum(CASE WHEN changes= 1 THEN 0 ELSE 1 END) AS pz_not_changed
FROM change_table
GROUP BY customer_id;

-- How many pizzas were delivered that had both exclusions and extras?

WITH change_table AS
(
	SELECT 
		c.pizza_id,
		CASE 
			WHEN c.exclusions != 0 AND c.extras != 0 THEN 1
			ELSE 0
		END AS changes
	FROM
		customer_orders c
	JOIN
		runner_orders r 
		ON c.order_id = r.order_id
	WHERE distance != 0
)
SELECT 
	COUNT(pizza_id) AS ex_clusion_tras
FROM
	change_table
WHERE 
	changes = 1;
    
-- What was the total volume of pizzas ordered for each hour of the day?

SELECT
	HOUR(order_time) AS h_o_day,
    COUNT(order_id) AS volume
FROM customer_orders
GROUP BY h_o_day
ORDER BY h_o_day;

-- What was the volume of orders for each day of the week?
-- 1 is sunday, 7 is saturday.

SELECT 
	DAYNAME(order_time) AS d_o_week,
    COUNT(order_id) AS volume
FROM customer_orders
GROUP BY d_o_week
ORDER BY DAYOFWEEK(order_time)

