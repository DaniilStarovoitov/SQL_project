/* 5. Má výška HDP vliv na změny ve mzdách a cenách potravin?
Neboli, pokud HDP vzroste výrazněji v jednom roce, projeví se to na cenách potravin či mzdách ve stejném nebo násdujícím roce výraznějším růstem?*/

CREATE OR REPLACE VIEW czechia_annual_payroll_and_price_change AS
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

SELECT
	gdp.year_of_measurement,
	main.payroll_percent_change AS percentage_change_in_salary,
	main.price_percent_change AS percentage_change_in_prices,
	gdp.gdp_percent_change AS percentage_change_in_gdp
FROM
	czechia_annual_payroll_and_price_change AS main
JOIN
	t_dan_starovoitov_project_SQL_secondary_final AS gdp
ON
	main.payroll_year = gdp.year_of_measurement
	AND gdp.country = 'Czech republic'
	AND gdp.GDP IS NOT NULL
GROUP BY
	main.payroll_year;