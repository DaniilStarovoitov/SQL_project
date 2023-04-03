-- 3. Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)? 

CREATE OR REPLACE VIEW czechia_annual_price_change AS
SELECT DISTINCT
	payroll_year,
	category_code,
	category,
	price_value
FROM
	t_dan_starovoitov_project_sql_primary_final;

SELECT
	category_code,
	category,
	AVG(price_percent_change) AS average_price_change
FROM
	(SELECT
		payroll_year,
		category_code,
		category,
		price_value,
		LEAD(price_value) OVER (PARTITION BY category_code ORDER BY category_code, payroll_year) AS next_value,
		ROUND(((LEAD(price_value) OVER (PARTITION BY category_code ORDER BY category_code, payroll_year) - price_value) / price_value) * 100, 2) AS price_percent_change
	FROM
		czechia_annual_price_change) subquery
GROUP BY
	category_code,
	payroll_year
ORDER BY
	AVG(price_percent_change) DESC;