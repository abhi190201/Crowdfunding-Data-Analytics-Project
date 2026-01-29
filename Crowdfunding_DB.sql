Create database Crowdfunding_DB;

use Crowdfunding_DB;

SHOW TABLES;

-- Requirement 1 & 4: Data Transformation

-- 1. Remove the old table if it exists
DROP TABLE IF EXISTS projects_final;

-- Create the master table
CREATE TABLE projects_final AS
SELECT *,
    FROM_UNIXTIME(created_at) AS created_at_natural,
    FROM_UNIXTIME(launched_at) AS launched_at_natural,
    FROM_UNIXTIME(deadline) AS deadline_natural,
    (goal * static_usd_rate) AS goal_usd
FROM projects;

-- Requirement 2: Calendar Table (Financial Year Starts April)
CREATE TABLE Calendar_Table AS
SELECT DISTINCT
    DATE(created_at_natural) AS Created_Date,
    YEAR(created_at_natural) AS Year,
    MONTH(created_at_natural) AS MonthNo,
    MONTHNAME(created_at_natural) AS MonthFullName,
    CONCAT('Q', QUARTER(created_at_natural)) AS Quarter,
    -- Financial Month Logic
    CASE 
        WHEN MONTH(created_at_natural) >= 4 THEN CONCAT('FM-', MONTH(created_at_natural) - 3)
        ELSE CONCAT('FM-', MONTH(created_at_natural) + 9)
    END AS FinancialMonth,
    -- Financial Quarter Logic
    CASE 
        WHEN MONTH(created_at_natural) BETWEEN 4 AND 6 THEN 'FQ-1'
        WHEN MONTH(created_at_natural) BETWEEN 7 AND 9 THEN 'FQ-2'
        WHEN MONTH(created_at_natural) BETWEEN 10 AND 12 THEN 'FQ-3'
        ELSE 'FQ-4'
    END AS FinancialQuarter
FROM projects_final;


-- Requirement 5: Project Overview KPIs
-- 5.1: Projects by Outcome
SELECT state, COUNT(*) AS Total_Projects FROM projects_final GROUP BY state;

SELECT * FROM crowdfunding_category LIMIT 5;
-- 5.2: Projects by Category (Assuming you have a category table named crowdfunding_category)
SELECT 
    c.name AS Category_Name,
    COUNT(p.ProjectID) AS Total_Projects,
    ROUND((COUNT(CASE WHEN p.state = 'successful' THEN 1 END) / COUNT(p.ProjectID)) * 100, 2) AS Success_Percentage
FROM projects_final p
JOIN crowdfunding_category c ON p.category_id = c.id
GROUP BY c.name
ORDER BY Success_Percentage DESC;

-- 5.3: Projects by Location
SELECT country, COUNT(*) AS Total FROM projects_final GROUP BY country;

-- 5.4: Projects by Year, Quarter, and Month
SELECT 
    c.Year, 
    c.FinancialQuarter, 
    c.MonthFullName, 
    COUNT(p.ProjectID) AS Total_Projects
FROM projects_final p
JOIN Calendar_Table c ON DATE(p.created_at_natural) = c.Created_Date
GROUP BY c.Year, c.FinancialQuarter, c.MonthFullName, c.MonthNo
ORDER BY c.Year DESC, c.MonthNo ASC;

-- Requirement 6 & 7: Successful Project Performance

-- 6: Financials and Duration
SELECT 
    SUM(pledged) AS Total_Raised,
    SUM(backers_count) AS Total_Backers,
    AVG(DATEDIFF(deadline_natural, launched_at_natural)) AS Avg_Days_Duration
FROM projects_final
WHERE state = 'successful';

-- 7: Top 5 by Backers
SELECT name, backers_count FROM projects_final 
WHERE state = 'successful' ORDER BY backers_count DESC LIMIT 5;

-- 7: Top 5 by Amount Raised
SELECT name, pledged FROM projects_final 
WHERE state = 'successful' ORDER BY pledged DESC LIMIT 5;

-- Requirement 8: Success Percentages
-- Success Rate by Category
SELECT 
    c.name AS Category_Name,
    COUNT(p.ProjectID) AS Total_Projects,
    (COUNT(CASE WHEN p.state = 'successful' THEN 1 END) / COUNT(p.ProjectID)) * 100 AS Success_Rate
FROM projects_final p
JOIN crowdfunding_category c ON p.category_id = c.id
GROUP BY c.name
ORDER BY Success_Rate DESC;