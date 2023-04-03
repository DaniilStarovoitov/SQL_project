-- First table

CREATE OR REPLACE TABLE temporary_table_payroll AS
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

CREATE OR REPLACE TABLE temporary_table_price AS
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
	temporary_table_payroll AS temp1
JOIN
	temporary_table_price AS temp2
ON
	temp1.payroll_year = temp2.price_date

-- Second table

CREATE OR REPLACE TABLE t_dan_starovoitov_project_SQL_secondary_final AS
SELECT
	country,
	`year` AS year_of_measurement,
	`year` + 1 AS next_year,
	GDP AS gdp,
	LEAD(gdp) OVER (PARTITION BY country ORDER BY country, `year`) AS next_year_gdp,
	ROUND((((LEAD(gdp) OVER (PARTITION BY country ORDER BY country, `year`)) - gdp) / gdp ) * 100,2) AS gdp_percent_change
FROM 
	economies
WHERE
	gdp is not NULL
ORDER BY
	country,
	year_of_measurement;