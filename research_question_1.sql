-- 1. Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?

CREATE OR REPLACE VIEW czechia_annual_salary_change AS
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
    payroll_year, 
    industry_branch_code, 
    industry_name,
    payroll_value AS current_year_salary,
    next_value AS next_year_salary,
    payroll_percent_change AS percentage_change_in_salary,
    CASE 
        WHEN payroll_percent_change > 0 THEN 'Salary has increased' 
        ELSE 'Salary has not increased' 
    END AS salary_change_result 
FROM 
    (SELECT
		payroll_year, 
		industry_branch_code, 
		industry_name,
		payroll_value,
        LEAD(payroll_value) OVER (PARTITION BY industry_branch_code ORDER BY payroll_year, industry_branch_code) AS next_value, 
        ROUND(((LEAD(payroll_value) OVER (PARTITION BY industry_branch_code ORDER BY payroll_year, industry_branch_code) - payroll_value) / payroll_value) * 100, 2) AS payroll_percent_change
	FROM 
        czechia_annual_salary_change) subquery;