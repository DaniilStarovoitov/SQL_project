-- 4. Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?

SELECT
	payroll_year,
	price_percent_change - payroll_percent_change AS percent_difference
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
	percent_difference DESC;