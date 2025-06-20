
-- Creating Schema
CREATE DATABASE HR_analytics;
Use HR_analytics;

-- Creating table
-- The .csv file needs to be loaded into a SQL table with correct columns.
DROP TABLE IF EXISTS Employees;
CREATE TABLE Employees (
    Age INT,
    Attrition VARCHAR(5),
    BusinessTravel VARCHAR(50),
    DailyRate INT,
    Department VARCHAR(50),
    DistanceFromHome INT,
    Education INT,
    EducationField VARCHAR(50),
    EmployeeCount INT,
    EmployeeNumber INT PRIMARY KEY,
    EnvironmentSatisfaction INT,
    Gender VARCHAR(10),
    HourlyRate INT,
    JobInvolvement INT,
    JobLevel INT,
    JobRole VARCHAR(100),
    JobSatisfaction INT,
    MaritalStatus VARCHAR(20),
    MonthlyIncome INT,
    MonthlyRate INT,
    NumCompaniesWorked INT,
    Over18 CHAR(1),
    OverTime VARCHAR(10),
    PercentSalaryHike INT,
    PerformanceRating INT,
    RelationshipSatisfaction INT,
    StandardHours INT,
    StockOptionLevel INT,
    TotalWorkingYears INT,
    TrainingTimesLastYear INT,
    WorkLifeBalance INT,
    YearsAtCompany INT,
    YearsInCurrentRole INT,
    YearsSinceLastPromotion INT,
    YearsWithCurrManager INT
);

--  Import CSV file into Table

-- Exploring the data

-- 1)Data Cleanup & Null Handling
-- 1.1)Count Missing Values
-- Check for missing values
-- Good data hygiene is essential before analysis.
-- Count ignores NULL, so we use CASE
-- can try for every column in table for through check.
SELECT 
  SUM(CASE 
        WHEN NumCompaniesWorked IS NULL THEN 1 ELSE 0 
	  END) AS Null_NumCompaniesWorked,
  SUM(CASE 
        WHEN TotalWorkingYears IS NULL THEN 1 ELSE 0 
	  END) AS Null_TotalWorkingYears
FROM employees;

-- 1.2)Fill NULL with Default Value
-- Substitute NULLs with a meaningful default.
-- creates a virtual table that always returns cleaned data
-- View(read-only), helpful for dashboards
CREATE VIEW Clean_employees AS
SELECT 
  EmployeeNumber,
  COALESCE(NumCompaniesWorked, 0) AS Clean_NumCompaniesWorked,
  COALESCE(TotalWorkingYears, 0) AS Clean_TotalWorkingYears
FROM employees;

-- Clean data
SELECT * 
FROM Clean_employees;

-- 2)Employee Demographics
-- 2.1) Gender Distribution
-- See how many male and female employees there are. Helpful for diversity analysis.
SELECT Gender,
COUNT(*) AS Total
FROM Employees
GROUP BY Gender
ORDER BY Total DESC;

-- 2.2) Education Field Breakdown
-- Identify which educational backgrounds are most common. Helps in recruitment targeting.
SELECT EducationField,
COUNT(*) AS Total
FROM Employees
GROUP BY EducationField
ORDER BY Total DESC;

-- 2.3)Age Group
-- Segment employees into age groups for better demographic insight.
SELECT 
  CASE 
    WHEN Age < 30 THEN 'Under 30'
    WHEN Age BETWEEN 30 AND 45 THEN '30–45'
    ELSE '45+'
  END AS AgeGroup,
  COUNT(*) AS Total
FROM Employees
GROUP BY AgeGroup
ORDER BY Total DESC;

-- 3)Job Roles and Departments
-- 3.1)Employees per Job Role
-- Shows how large each role is. 
-- Useful to know if a role is over- or under-staffed.
SELECT JobRole, 
COUNT(*) AS Total
FROM Employees
GROUP BY JobRole
ORDER BY Total DESC;

-- 3.2)Department Sizes
-- See how employees are distributed across departments.
SELECT Department, 
COUNT(*) AS Total
FROM Employees
GROUP BY Department
ORDER BY Total DESC;

-- 4)Salary & Work Hours
-- 4.1 Average Salary by Role
-- Helps detect pay discrepancies between roles.
SELECT JobRole, 
ROUND(AVG(MonthlyIncome), 2) AS AvgIncome
FROM Employees
GROUP BY JobRole
ORDER BY AvgIncome DESC;

-- 4.2)Work-Life Balance by Department
-- Identify which departments are more stressful.
-- Assuming WorkLifeBalance is on a 1–4 scale, where 4 = Best
SELECT Department, 
ROUND(AVG(WorkLifeBalance), 2) AS AvgWorkLife
FROM employees
GROUP BY Department
ORDER BY AvgWorkLife DESC;

-- 5)Attrition Analysis
-- 5.1)Overall Attrition Rate
-- Calculate company-wide attrition in percentage.
SELECT 
  COUNT(*) AS TotalEmployees,
  SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS EmployeesLeft,
  ROUND(100.0 * SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS AttritionRate
FROM employees;

-- 5.2)Attrition by Department
-- Spot departments with high turnover to take corrective action.
-- Attribution by other factors can be done in dashboards directly and visually, without needing to write complex SQL manually.

SELECT 
  Department,
  COUNT(*) AS Total,
  SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS EmployeesLeft,
  ROUND(100.0 * SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS AttritionRate
FROM employees
GROUP BY Department
ORDER BY AttritionRate DESC;

-- 5.3)Does Overtime Increase Attrition?
-- Helps see whether working overtime contributes to employees quitting.
SELECT OverTime, 
Attrition, 
COUNT(*) AS Total
FROM employees
GROUP BY OverTime, Attrition;

-- 6)Satisfaction & Performance
-- 6.1)Job Satisfaction Breakdown
-- How happy are employees in their roles? 
-- Low satisfaction can signal future attrition.
SELECT JobSatisfaction, 
COUNT(*) AS Total
FROM employees
GROUP BY JobSatisfaction
ORDER BY Total DESC;

-- 6.2) Performance Rating vs Attrition
-- Explore if high or low performers are more likely to leave.
SELECT PerformanceRating,
  COUNT(*) AS Total,
  SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS EmployeesLeft
FROM employees
GROUP BY PerformanceRating
ORDER BY Total DESC;

-- 6.3) YearsSinceLastPromotion  vs Attrition
-- Explore if high or low performers are more likely to leave.
SELECT 
  CASE 
    WHEN YearsSinceLastPromotion < 5 THEN '<5 years'
    WHEN YearsSinceLastPromotion BETWEEN 5 AND 10 THEN '5-10 years'
    ELSE '10+ years'
  END AS PromotionGapGroup,
  COUNT(*) AS Total,
  SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS EmployeesLeft,
  ROUND(100.0 * SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS AttritionRate
FROM employees
GROUP BY PromotionGapGroup 
ORDER BY AttritionRate DESC;


-- 7)Advanced Risk Tracking (CTE + CASE + RANK)
-- 7.1)Flag High-Risk Employees
-- Simple rule-based model to predict who might quit soon.
-- can make own condition.
SELECT 
  EmployeeNumber,
  JobSatisfaction,
  OverTime,
  YearsSinceLastPromotion,
  CASE
    WHEN JobSatisfaction <= 2 AND OverTime = 'Yes' AND YearsSinceLastPromotion >= 3 THEN 'High Risk'
    ELSE 'Low Risk'
  END AS AttritionRisk
FROM employees;

-- 7.2)Top 3 Employees Waiting for Promotion (by Role)
-- Helps HR identify employees who’ve been waiting longest in each role — prioritize them for promotion review.
-- Flag who might be frustrated and at attrition risk
-- can use DENSE_RANK() or ROW_NUMBER()(Window function within CTE)
WITH PromotionRank AS (
  SELECT 
    EmployeeNumber,
    JobRole,
    YearsSinceLastPromotion,
    RANK() OVER (PARTITION BY JobRole ORDER BY YearsSinceLastPromotion DESC) AS RankInRole
  FROM employees
)
SELECT * 
FROM PromotionRank
WHERE RankInRole <= 3;

-- 8)Window Functions & Trends
-- 8.1) Rank Employees by Salary Within Department
-- Compare salaries in context.
SELECT 
  EmployeeNumber,
  Department,
  MonthlyIncome,
  PerformanceRating,
  Attrition,
  YearsSinceLastPromotion,
  RANK() OVER (PARTITION BY Department ORDER BY MonthlyIncome DESC) AS DeptSalaryRank
FROM employees;


-- 9) Executive Summary: One-Liner Stats
-- Use for dashboards or reports —> gives key metrics in a single shot.
-- It gives key KPIs(Key Performance Indicators)
SELECT 
  COUNT(*) AS TotalEmployees,
  SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS EmployeesLeft,
  ROUND(AVG(MonthlyIncome), 2) AS AvgSalary,
  ROUND(AVG(YearsSinceLastPromotion), 2) AS AvgYearsSincePromotion,
  ROUND(100.0 * SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS AttritionRate
FROM employees;

