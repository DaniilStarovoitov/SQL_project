-- First table

CREATE OR REPLACE TABLE temp1 AS
SELECT
	cp.payroll_year,
	cp.industry_branch_code,
	cpib.name AS industry_name,
	ROUND(AVG(cp.value)) AS payroll_value
FROM
	czechia_payroll AS cp
JOIN
	czechia_payroll_industry_branch AS cpib
ON
	cp.industry_branch_code = cpib.code
	AND cp.value_type_code = 5958
	AND cp.calculation_code = 100
GROUP BY
	payroll_year,
	industry_branch_code;

CREATE OR REPLACE TABLE temp2 AS
SELECT
	YEAR(cpr.date_from) AS price_date,
	cpr.category_code,
	cpc.name AS category,
	ROUND(AVG(cpr.value)) AS price_value
FROM
	czechia_price AS cpr
JOIN
	czechia_price_category AS cpc 
ON
	cpr.category_code = cpc.code
	AND cpr.region_code IS NULL
GROUP BY
	YEAR(cpr.date_from),
	category_code;

CREATE OR REPLACE TABLE t_dan_starovoitov_project_SQL_primary_final AS
SELECT
	temp1.payroll_year,
	temp1.industry_branch_code,
	temp1.industry_name,
	temp1.payroll_value,
	temp2.price_date,
	temp2.category_code,
	temp2.category,
	temp2.price_value	
FROM
	temp1
JOIN
	temp2
ON
	temp1.payroll_year = temp2.price_date

-- Second table

CREATE OR REPLACE TABLE t_dan_starovoitov_project_SQL_secondary_final AS
SELECT
	country,
	`year` AS year_of_measurement,
	`year` + 1 AS next_year,
	GDP,
	LEAD(GDP) OVER (PARTITION BY country ORDER BY country, `year`) AS next_year_gdp,
	ROUND((((LEAD(GDP) OVER (PARTITION BY country ORDER BY country, `year`)) - GDP) / GDP ) * 100,2) AS gdp_percent_change
FROM 
	economies
WHERE
	GDP is not NULL
ORDER BY
	country,
	year_of_measurement;
	
-- 1. Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?

CREATE OR REPLACE VIEW one AS
SELECT DISTINCT
	payroll_year, 
    industry_branch_code, 
    industry_name,
    payroll_value
FROM
	t_dan_starovoitov_project_sql_primary_final
ORDER BY
	industry_branch_code,
	payroll_year;

SELECT
    payroll_year AS 'Year', 
    industry_branch_code AS 'Industry branch code', 
    industry_name AS 'Industry name',
    payroll_value AS 'Salary',
    next_value AS 'Next year salary',
    payroll_percent_change AS 'Percentage change in salary',
    CASE 
        WHEN payroll_percent_change > 0 THEN 'Salary has increased' 
        ELSE 'Salary has not increased' 
    END AS Result 
FROM 
    (SELECT
		payroll_year, 
		industry_branch_code, 
		industry_name,
		payroll_value,
        LEAD(payroll_value) OVER (PARTITION BY industry_branch_code ORDER BY payroll_year, industry_branch_code) AS next_value, 
        ROUND(((LEAD(payroll_value) OVER (PARTITION BY industry_branch_code ORDER BY payroll_year, industry_branch_code) - payroll_value) / payroll_value) * 100, 2) AS payroll_percent_change
	FROM 
        one) subquery;

-- 2. Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?

SELECT
	payroll_year AS 'Year' ,
	industry_name AS 'Indutry name',
	category AS 'Category name',
	ROUND(payroll_value / price_value) AS 'Amount per salary'
FROM
	t_dan_starovoitov_project_SQL_primary_final
WHERE
	category_code IN (111301, 114201)
	AND payroll_year IN (2006, 2018)
ORDER BY
	category,
	payroll_year;

-- 3. Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)? 

CREATE OR REPLACE VIEW two AS
SELECT DISTINCT
	payroll_year,
	category_code,
	category,
	price_value
FROM
	t_dan_starovoitov_project_sql_primary_final;

SELECT
	category_code AS 'Category code',
	category AS 'Category name',
	AVG(price_percent_change) AS 'Average price change'
FROM
	(SELECT
		payroll_year,
		category_code,
		category,
		price_value,
		LEAD(price_value) OVER (PARTITION BY category_code ORDER BY category_code, payroll_year) AS next_value,
		ROUND(((LEAD(price_value) OVER (PARTITION BY category_code ORDER BY category_code, payroll_year) - price_value) / price_value) * 100, 2) AS price_percent_change
	FROM
		two) subquery
GROUP BY
	category_code,
	payroll_year
ORDER BY
	AVG(price_percent_change) DESC;

-- 4. Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?

SELECT
	payroll_year AS 'Year',
	price_percent_change - payroll_percent_change AS Percent_difference
FROM
	(SELECT
		payroll_year,
		payroll_value,
		LEAD(payroll_value) OVER (PARTITION BY industry_branch_code ORDER BY payroll_year, industry_branch_code) AS next_payroll_value,
		ROUND(((LEAD(payroll_value) OVER (PARTITION BY industry_branch_code ORDER BY payroll_year, industry_branch_code) - payroll_value) / payroll_value) * 100, 2) AS payroll_percent_change,
		price_value,
		LEAD(price_value) OVER (PARTITION BY category_code ORDER BY category_code, payroll_year) AS next_price_value,
		ROUND(((LEAD(price_value) OVER (PARTITION BY category_code ORDER BY category_code, payroll_year) - price_value) / price_value) * 100, 2) AS price_percent_change
	FROM
		t_dan_starovoitov_project_sql_primary_final
	GROUP BY
		payroll_year) subquery
ORDER BY
	Percent_difference DESC;

CREATE OR REPLACE VIEW five AS
SELECT
	payroll_year,
	payroll_value,
	LEAD(payroll_value) OVER (PARTITION BY industry_branch_code ORDER BY payroll_year, industry_branch_code) AS next_payroll_value,
	ROUND(((LEAD(payroll_value) OVER (PARTITION BY industry_branch_code ORDER BY payroll_year, industry_branch_code) - payroll_value) / payroll_value) * 100, 2) AS payroll_percent_change,
	price_value,
	LEAD(price_value) OVER (PARTITION BY category_code ORDER BY category_code, payroll_year) AS next_price_value,
	ROUND(((LEAD(price_value) OVER (PARTITION BY category_code ORDER BY category_code, payroll_year) - price_value) / price_value) * 100, 2) AS price_percent_change
FROM
	t_dan_starovoitov_project_sql_primary_final
GROUP BY
	payroll_year;

/* 5. Má výška HDP vliv na změny ve mzdách a cenách potravin?
Neboli, pokud HDP vzroste výrazněji v jednom roce, projeví se to na cenách potravin či mzdách ve stejném nebo násdujícím roce výraznějším růstem?*/

SELECT
	five.payroll_year AS 'Year',
	five.payroll_percent_change AS 'Percentage change in salary',
	five.price_percent_change AS 'percentage change in prices',
	gdp.gdp_percent_change AS 'percentage change in GDP'
FROM
	five
JOIN
	t_dan_starovoitov_project_SQL_secondary_final AS gdp
ON
	five.payroll_year = gdp.year_of_measurement
	AND gdp.country = 'Czech republic'
	AND gdp.GDP IS NOT NULL
GROUP BY
	five.payroll_year;