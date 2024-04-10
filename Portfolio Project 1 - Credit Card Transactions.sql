-- SQL porfolio project.
-- download credit card transactions dataset from below link :
-- https://www.kaggle.com/datasets/thedevastator/analyzing-credit-card-spending-habits-in-india
-- import the dataset in sql server with table name : credit_card_transcations
-- change the column names to lower case before importing data to sql server.Also replace space within column names with underscore.
-- (alternatively you can use the dataset present in zip file)
-- while importing make sure to change the data types of columns. by defualt it shows everything as varchar.

USE credit_card_project;


-- write 4-6 queries to explore the dataset and put your findings 

SELECT *
FROM credit_card_transcations ;

-- solve below questions
-- 1- write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends 
WITH spends_on_city as (SELECT city, SUM(amount) as city_spends 
FROM credit_card_transcations
GROUP BY city),
rank_on_city as (SELECT *,
DENSE_RANK() OVER (ORDER BY city_spends DESC) AS city_rank
FROM spends_on_city)
SELECT city_rank, city, city_spends, (city_spends/(SELECT SUM(city_spends) FROM rank_on_city))*100 AS spent_percent
FROM rank_on_city
WHERE city_rank < 6;


-- 2- write a query to print highest spend month for each year and amount spent in that month for each card type



WITH cte1 as(
	SELECT card_type, YEAR(transaction_date) yt,
	MONTH(transaction_date) mt, SUM(amount) as total_spend
	FROM credit_card_transcations
	GROUP BY card_type, YEAR(transaction_date), MONTH(transaction_date)
), cte2 as(
	SELECT *, DENSE_RANK() OVER(PARTITION BY card_type ORDER BY total_spend DESC) as rn
	FROM cte1
)
SELECT *
FROM cte2
WHERE rn =1;

-- WITH spent_of_month AS (
-- 	SELECT YEAR(transaction_date) as year, MONTH(transaction_date) AS month, card_type, SUM(amount) as monthly_spent_each_card
--     FROM credit_card_transcations
--     GROUP BY YEAR(transaction_date), MONTH(transaction_date), card_type
--     ORDER BY year, month 
--     ),
-- spend_of_month_with_card as (
-- 	SELECT year, month , SUM(monthly_spent_each_card) as monthly_spent, DENSE_RANK() OVER(PARTITION BY year ORDER BY SUM(monthly_spent_each_card)) AS rank_monthly_spent
--     FROM spent_of_month
--     GROUP BY year, month 
-- ),
-- highest_month as (
-- SELECT * 
-- FROM spend_of_month_with_card
-- WHERE rank_monthly_spent = 1
-- ),
-- cte as (
-- 	SELECT som.*, 
--     DENSE_RANK() OVER(PARTITION BY som.year ORDER BY som.monthly_spent_each_card) AS highest_card
-- 	FROM spent_of_month as som
-- 	JOIN highest_month as hm
-- 	ON CONCAT(som.year, "-" , som.month) = CONCAT(hm.year, "-" , hm.month)
-- )
-- SELECT *
-- FROM cte
-- WHERE highest_card=1 ;





-- 3- write a query to print the transaction details(all columns from the table) for each card type when
	-- it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)
    
	WITH total_spent AS (
			SELECT *,
			SUM(amount) OVER(PARTITION BY card_type ORDER BY transaction_date, transaction_id) AS sum_of_spent
			FROM credit_card_transcations
    ),
    total_on_each_card as (
			SELECT *, 
			DENSE_RANK() OVER(PARTITION BY card_type ORDER BY sum_of_spent) AS total_spent_each_card
			FROM total_spent
			WHERE sum_of_spent >= 1000000
    )
    SELECT *
    FROM total_on_each_card
    WHERE total_spent_each_card = 1;
    
-- 4- write a query to find city which had lowest percentage spend for gold card type

WITH each_city_amount as (
	SELECT city, SUM(amount) as amount_spent_each_city
	FROM credit_card_transcations
	WHERE card_type = "Gold"
	GROUP BY city
),
city_percentage as (
	SELECT *, (amount_spent_each_city/(SELECT SUM(amount_spent_each_city) FROM each_city_amount))*100 AS percent_of_spent
	FROM each_city_amount
),
cte as (
	SELECT *,
    DENSE_RANK() OVER(ORDER BY percent_of_spent) AS spent_rank
    FROM city_percentage
)
SELECT *
FROM cte
WHERE spent_rank = 1;


-- 5- write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)
WITH exp_type_amount as (
	SELECT city , exp_type , SUM(amount) as amount_each_exp
	FROM credit_card_transcations
	GROUP BY city , exp_type
),
rank_of_exp as (
	SELECT *,
    DENSE_RANK() OVER(PARTITION BY city ORDER BY amount_each_exp) AS lowest_exp,
    DENSE_RANK() OVER(PARTITION BY city ORDER BY amount_each_exp DESC ) AS highest_exp
    FROM exp_type_amount
),
lowest_exp_type as (
	SELECT *
	FROM rank_of_exp
	WHERE lowest_exp = 1
),
highest_exp_type as (
	SELECT *
	FROM rank_of_exp
	WHERE highest_exp = 1
)
SELECT low.city, high.exp_type as highest_expense_type, low.exp_type as lowest_expense_type
FROM lowest_exp_type AS low
JOIN highest_exp_type AS high
ON low.city = high.city;



-- 6- write a query to find percentage contribution of spends by females for each expense type
WITH spent_on_exp as (
	SELECT gender, exp_type, SUM(amount) as spent_for_each_exp
	FROM credit_card_transcations
	WHERE gender = "F"
	GROUP BY gender, exp_type
)
SELECT *, (spent_for_each_exp/(SELECT SUM(amount) FROM credit_card_transcations WHERE gender = "F"))*100 AS spent_for_exp_perc
FROM spent_on_exp;

-- 7- which card and expense type combination saw highest month over month growth in Jan-2014
WITH cte1 as(
	SELECT card_type, exp_type, YEAR(transaction_date) yt, 
    MONTH(transaction_date) mt, SUM(amount) as total_spend
	FROM credit_card_transcations
	GROUP BY card_type, exp_type, YEAR(transaction_date), MONTH(transaction_date)
), cte2 as(
	SELECT *, 
    LAG(total_spend,1) OVER(PARTITION BY card_type, exp_type ORDER BY yt,mt) as prev_mont_spend
	FROM cte1
)
SELECT *, (total_spend-prev_mont_spend) as mom_growth
FROM cte2
WHERE prev_mont_spend IS NOT NULL AND yt=2014 AND mt=1
ORDER BY mom_growth DESC
LIMIT 1;

-- 8- during weekends which city has highest total spend to total no of transcations ratio 
WITH cte as (
	SELECT city , SUM(amount) / COUNT(*) AS totalspent_to_trans_ratio,
	DENSE_RANK() OVER(ORDER BY (SUM(amount) / COUNT(*)) DESC) AS ratio_rank
	FROM credit_card_transcations
	WHERE DAYNAME(transaction_date) = 'Saturday' OR DAYNAME(transaction_date) = 'Sunday'
	GROUP BY city
)
SELECT *
FROM cte 
WHERE ratio_rank = 1;

-- 9- which city took least number of days to reach its 500th transaction after the first transaction in that city
WITH date_ordered AS (
	SELECT *,
	RANK() OVER(PARTITION BY city ORDER BY transaction_date, transaction_id) AS date_rank
	FROM credit_card_transcations
),
last_date_tran as (
	SELECT city, MAX(transaction_date) AS last_date
	FROM date_ordered
	WHERE date_rank = 500
    GROUP BY city
),
first_date_tran as (
	SELECT city, MIN(transaction_date) AS first_date
    FROM date_ordered
	WHERE date_rank = 1
    GROUP BY city
),
last_first_tran as (
	SELECT las.*, fir.first_date
	FROM last_date_tran AS las
	JOIN first_date_tran as fir
	ON las.city = fir.city
),
cte as (
	SELECT *, DATEDIFF(last_date, first_date) AS days_long,
	DENSE_RANK() OVER(ORDER BY  DATEDIFF(last_date, first_date)) AS days_rank
	FROM last_first_tran
)
SELECT *
FROM cte
WHERE days_rank = 1;





-- once you are done with this create a github repo to put that link in your resume. Some example github links: