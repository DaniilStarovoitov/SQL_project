-- 2. Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?

SELECT
	payroll_year,
	industry_name,
	category,
	ROUND(payroll_value / price_value) AS amount_per_salary
FROM
	t_dan_starovoitov_project_SQL_primary_final
WHERE
	category_code IN (111301, 114201)
	AND payroll_year IN (2006, 2018)
ORDER BY
	category,
	payroll_year;