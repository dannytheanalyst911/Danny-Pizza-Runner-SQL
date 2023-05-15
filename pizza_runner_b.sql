-- B. Runner and Customer Experience

-- How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

SELECT
	WEEK(registration_date,5) as week_period, -- 2021-01-01 was Friday and 5 is set start of week is Ftiday, and week count start from 0.
	COUNT(runner_id) as runner_cnt
FROM
	runners
GROUP BY week_period;

-- What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
-- The duration column was not in the same value accross the row so we have to clean it first.
CREATE TABLE runner_orders_pre
SELECT
	order_id,
	runner_id,
	CASE
		WHEN pickup_time = 'null' THEN null
		ELSE pickup_time
	END AS pick_up_time,
	CASE
		WHEN distance = 'null' THEN null
		ELSE regexp_replace(distance, '[a-z]+', '')
	END AS distance_km,
	CASE
		WHEN duration = 'null' THEN null
		ELSE regexp_replace(duration, '[a-z]+', '')
		END AS duration_mins,
	CASE
		WHEN cancellation = '' THEN null
		WHEN cancellation = 'null' THEN null
		ELSE cancellation
		END AS cancellation               
FROM runner_orders;

CREATE TABLE runner_orders_post
	SELECT
		order_id,
		runner_id,
		pick_up_time,
		CAST(distance_km AS DECIMAL(3,1)) AS distance_km, 
		CAST(duration_mins AS SIGNED INT) AS duration_mins,
		cancellation
    FROM runner_orders_pre;
    
SELECT 
    runner_id,
    ROUND(AVG(MINUTE(TIMEDIFF(r.pick_up_time, c.order_time))),2) AS time_mins
FROM
    runner_orders_post r
        JOIN
    customer_orders c ON r.order_id = c.order_id
GROUP BY runner_id;



-- Is there any relationship between the number of pizzas and how long the order takes to prepare?

SELECT 
    c.order_id,
    ROUND(AVG(MINUTE(TIMEDIFF(r.pick_up_time, c.order_time))),2) AS avg_time_mins,
    COUNT(c.order_id) AS num_of_pz
FROM
    runner_orders_post r
JOIN
    customer_orders c ON r.order_id = c.order_id
WHERE
    duration_mins IS NOT NULL
GROUP BY c.order_id
ORDER BY num_of_pz;

-- Yes, the more pizzas in the order, the more time it need to prepare.

-- What was the average distance travelled for each customer?

SELECT 
    c.customer_id, ROUND(AVG(distance_km), 2) AS avg_distance_km
FROM
    customer_orders c
        JOIN
    runner_orders_post r ON r.order_id = c.order_id
WHERE
    distance_km != 0
GROUP BY c.customer_id;

-- What was the difference between the longest and shortest delivery times for all orders?

SELECT 
    MAX(duration_mins) - MIN(duration_mins) AS time_diff_mins
FROM
    runner_orders_post;

-- What was the average speed for each runner for each delivery and do you notice any trend for these values?
-- hypothesis 1: the more pizza in the order, the more time needed for delivery
SELECT 
    *,
    AVG(r.duration_mins) AS avg_speed,
    COUNT(c.order_id) AS pz_amount
FROM
    runner_orders_post r
        JOIN
    customer_orders c ON r.order_id = c.order_id
GROUP BY r.runner_id , r.order_id
ORDER BY pz_amount;
-- there are no colleration.

-- hypothesis 2: the more far away the customer, the more time needed to deliver the pizzas.
SELECT 
    r.order_id,
    r.runner_id,
    ROUND(AVG(r.duration_mins), 2) AS avg_speed,
    distance_km
FROM
    runner_orders_post r
        JOIN
    customer_orders c ON r.order_id = c.order_id
WHERE
    distance_km != 0
GROUP BY r.runner_id , c.order_id
ORDER BY r.runner_id , r.distance_km , avg_speed; 
-- Yes there is a colleration.

-- What is the successful delivery percentage for each runner?

SELECT 
    runner_id,
    CONCAT(ROUND(SUM(CASE
                        WHEN cancellation IS NULL THEN 1
                        ELSE 0
                    END) / COUNT(runner_id) * 100,
                    2),
            '%') AS successful_rate
FROM
    runner_orders_post
GROUP BY runner_id