CREATE DATABASE IF NOT EXISTS employee_analysis;
USE employee_analysis;

DROP TABLE IF EXISTS EmployeeData_Raw;
CREATE EXTERNAL TABLE EmployeeData_Raw (
    job_id INT,
    job_title STRING,
    experience_years INT,
    education_level STRING,
    skills_count INT,
    industry STRING,
    company_size STRING,
    location STRING,
    remote_work STRING,
    call_log INT,
    salary DOUBLE,
    date_of_marriage STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
TBLPROPERTIES("skip.header.line.count"="1");

LOAD DATA INPATH '/user/hive/employee_data/EmployeeDataset.csv' INTO TABLE EmployeeData_Raw;

-- Step 2: Clean the table
DROP TABLE IF EXISTS EmployeeData;
CREATE TABLE EmployeeData AS 
SELECT 
    job_id,
    COALESCE(experience_years, 0) AS experience_years,
    INITCAP(education_level) AS education_level,
    IF(location = 'Remote', 'Unknown', location) AS location,
    IF(salary < 1000, salary * 1000, salary) AS salary,
    TRIM(date_of_marriage) AS date_of_marriage,
    job_title, skills_count, industry, company_size, remote_work, call_log
FROM EmployeeData_Raw;

-- Step 3: Split job title
SELECT '--- TASK 2: SPLIT JOB TITLE ---';
SELECT 
  split(job_title, ' ')[0] AS first_name, 
  substr(job_title, length(split(job_title, ' ')[0]) + 2) AS others 
FROM EmployeeData 
LIMIT 10;

-- Step 4: PhD < 10 years experience
SELECT '--- TASK 3: PhD Count ---';
SELECT 
  location AS country, 
  COUNT(*) as phd_count
FROM EmployeeData
WHERE LOWER(education_level) LIKE '%phd%' AND experience_years < 10
GROUP BY location;

-- Step 5: Skills count ascending
SELECT '--- TASK 4: Skills count ascending ---';
SELECT 
  skills_count, 
  COUNT(*) as total_employees
FROM EmployeeData
GROUP BY skills_count
ORDER BY skills_count ASC;

-- Step 6: Growth rate
SELECT '--- TASK 5: Call log totals and averages ---';
SELECT 
  education_level,
  SUM(call_log) AS total_call_log,
  AVG(call_log) AS avg_call_log
FROM EmployeeData
WHERE LOWER(education_level) IN ('phd', 'bachelor', 'high school')
GROUP BY education_level;

-- Step 7: Predict future value
SELECT '--- TASK 6: Predicted Call Log ---';
SELECT 
  education_level,
  AVG(call_log) AS current_avg_call_log,
  AVG(call_log) * 1.10 AS predicted_future_value
FROM EmployeeData
WHERE LOWER(education_level) IN ('phd', 'bachelor', 'high school')
GROUP BY education_level;
