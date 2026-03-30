-- queries.sql — SQL Analytics Lab
-- Module 3: SQL & Relational Data
--
-- Instructions:
--   Write your SQL query beneath each comment block.
--   Do NOT modify the comment markers (-- Q1, -- Q2, etc.) — the autograder uses them.
--   Test each query locally: psql -h localhost -U postgres -d testdb -f queries.sql
--
-- ============================================================

-- Q1: Employee Directory with Departments
-- List all employees with their department name, sorted by department (asc) then salary (desc).
-- Expected columns: first_name, last_name, title, salary, department_name
-- SQL concepts: JOIN, ORDER BY
SELECT e.first_name, e.last_name, d.name AS department_name, e.salary
FROM employees e
JOIN departments d ON e.department_id = d.department_id
ORDER BY d.name ASC, e.salary DESC;


-- Q2: Department Salary Analysis
-- Total salary expenditure by department. Only departments with total > 150,000.
-- Expected columns: department_name, total_salary
-- SQL concepts: GROUP BY, HAVING, SUM
SELECT 
    d.name AS department_name, 
    SUM(e.salary) AS total_salary
FROM employees e
JOIN departments d ON e.department_id = d.department_id
GROUP BY d.name
HAVING SUM(e.salary) > 150000;


-- Q3: Highest-Paid Employee per Department
-- For each department, find the employee with the highest salary.
-- Expected columns: department_name, first_name, last_name, salary
-- SQL concepts: Window function (ROW_NUMBER or RANK), CTE
WITH RankedEmployees AS (
    SELECT 
        d.name AS department_name,
        e.first_name,
        e.last_name,
        e.salary,
        ROW_NUMBER() OVER(PARTITION BY e.department_id ORDER BY e.salary DESC) AS rank
    FROM employees e
    JOIN departments d ON e.department_id = d.department_id
)
SELECT department_name, first_name, last_name, salary
FROM RankedEmployees
WHERE rank = 1;


-- Q4: Project Staffing Overview
-- All projects with employee count and total hours. Include projects with 0 assignments.
-- Expected columns: project_name, employee_count, total_hours
-- SQL concepts: LEFT JOIN, GROUP BY, COALESCE
SELECT p.name AS project_name, COUNT(pa.employee_id) AS employee_count, COALESCE(SUM(pa.hours_allocated), 0) AS total_hours
FROM projects p
LEFT JOIN project_assignments pa ON p.project_id = pa.project_id
GROUP BY p.project_id, p.name;


-- Q5: Above-Average Departments
-- Departments where average salary exceeds the company-wide average salary.
-- Expected columns: department_name, avg_salary
-- SQL concepts: CTE
WITH CompanyAverage AS (SELECT AVG(salary) AS company_avg_salary FROM employees),
DepartmentAverage AS (
    SELECT d.name AS department_name, AVG(e.salary) AS avg_salary
    FROM employees e
    JOIN departments d ON e.department_id = d.department_id
    GROUP BY d.name
)
SELECT da.department_name, ROUND(da.avg_salary, 2) AS avg_salary, ROUND(ca.company_avg_salary, 2) AS company_average
FROM DepartmentAverage da
CROSS JOIN CompanyAverage ca
WHERE da.avg_salary > ca.company_avg_salary;


-- Q6: Running Salary Total
-- Each employee's salary and running total within their department, ordered by hire date.
-- Expected columns: department_name, first_name, last_name, hire_date, salary, running_total
-- SQL concepts: Window function (SUM OVER)
SELECT d.name AS department_name, e.first_name, e.last_name, e.hire_date, e.salary,
SUM(e.salary) OVER(PARTITION BY e.department_id ORDER BY e.hire_date) AS running_total
FROM employees e
JOIN departments d ON e.department_id = d.department_id;


-- Q7: Unassigned Employees
-- Employees not assigned to any project.
-- Expected columns: first_name, last_name, department_name
-- SQL concepts: LEFT JOIN + NULL check (or NOT EXISTS)
SELECT e.first_name, e.last_name, d.name AS department_name
FROM employees e
JOIN departments d ON e.department_id = d.department_id
LEFT JOIN project_assignments pa ON e.employee_id = pa.employee_id
WHERE pa.project_id IS NULL;


-- Q8: Hiring Trends
-- Month-over-month hire count.
-- Expected columns: hire_year, hire_month, hires
-- SQL concepts: EXTRACT, GROUP BY, ORDER BY
SELECT EXTRACT(YEAR FROM hire_date) AS hire_year, EXTRACT(MONTH FROM hire_date) AS hire_month, COUNT(employee_id) AS hires
FROM employees
GROUP BY EXTRACT(YEAR FROM hire_date), EXTRACT(MONTH FROM hire_date)
ORDER BY hire_year ASC, hire_month ASC;


-- Q9: Schema Design — Employee Certifications
-- Design and implement a certifications tracking system.
--
-- Tasks:
-- 1. CREATE TABLE certifications (certification_id SERIAL PK, name VARCHAR NOT NULL, issuing_org VARCHAR, level VARCHAR)
-- 2. CREATE TABLE employee_certifications (id SERIAL PK, employee_id FK->employees, certification_id FK->certifications, certification_date DATE NOT NULL)
-- 3. INSERT at least 3 certifications and 5 employee_certification records
-- 4. Write a query listing employees with their certifications (JOIN across 3 tables)
--    Expected columns: first_name, last_name, certification_name, issuing_org, certification_date

CREATE TABLE certifications (
    certification_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    issuing_org VARCHAR(255),
    level VARCHAR(50)
);


CREATE TABLE employee_certifications (
    id SERIAL PRIMARY KEY,
    employee_id INT REFERENCES employees(employee_id) ON DELETE CASCADE,
    certification_id INT REFERENCES certifications(certification_id) ON DELETE CASCADE,
    certification_date DATE NOT NULL
);


INSERT INTO certifications (name, issuing_org, level) VALUES
('AWS Certified Solutions Architect', 'Amazon Web Services', 'Intermediate'),
('Project Management Professional (PMP)', 'PMI', 'Advanced'),
('Certified ScrumMaster (CSM)', 'Scrum Alliance', 'Beginner');

INSERT INTO employee_certifications (emp_id, certification_id, certification_date) VALUES
(1, 1, '2023-05-15'),
(2, 2, '2022-11-10'),
(3, 3, '2024-01-20'),
(1, 3, '2023-08-05'),
(4, 1, '2023-12-01');


SELECT 
    e.name AS employee_name,
    c.name AS certification_name,
    c.issuing_org,
    ec.certification_date
FROM employees e
JOIN employee_certifications ec ON e.emp_id = ec.emp_id
JOIN certifications c ON ec.certification_id = c.certification_id;