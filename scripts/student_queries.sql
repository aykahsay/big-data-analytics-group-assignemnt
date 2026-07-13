CREATE DATABASE IF NOT EXISTS student_analysis;
USE student_analysis;

DROP TABLE IF EXISTS student_performance_raw;
CREATE EXTERNAL TABLE student_performance_raw (
    student_id STRING,
    name STRING,
    gender STRING,
    age INT,
    department STRING,
    program STRING,
    year INT,
    semester INT,
    attendance INT,
    assignment INT,
    cat INT,
    finalexam INT,
    studyhours INT,
    internetaccess STRING,
    device STRING,
    parentincome INT,
    scholarship STRING,
    skillscount INT,
    projects INT,
    lmslogins INT,
    libraryvisits INT,
    location STRING,
    graduated STRING,
    placement STRING,
    gpa DOUBLE,
    total DOUBLE,
    grade STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
TBLPROPERTIES("skip.header.line.count"="1");

LOAD DATA INPATH '/user/hive/student_data/student_performance.csv' INTO TABLE student_performance_raw;

-- Clean Data Table
DROP TABLE IF EXISTS student_performance;
CREATE TABLE student_performance AS
SELECT * FROM student_performance_raw;

SELECT '--- 1. Count Students by Department ---';
SELECT
department,
COUNT(*) AS total_students
FROM student_performance
GROUP BY department
ORDER BY total_students DESC;

SELECT '--- 2. Average GPA by Department ---';
SELECT
department,
ROUND(AVG(gpa),2) AS average_gpa
FROM student_performance
GROUP BY department
ORDER BY average_gpa DESC;

SELECT '--- 3. Students with Attendance Below 60% ---';
SELECT
student_id,
name,
department,
attendance
FROM student_performance
WHERE attendance < 60
ORDER BY attendance;

SELECT '--- 4. Placement Rate by Program ---';
SELECT
program,
COUNT(*) AS graduates,
SUM(CASE WHEN placement='Yes' THEN 1 ELSE 0 END) AS placed_students,
ROUND(
100.0 * SUM(CASE WHEN placement='Yes' THEN 1 ELSE 0 END) / COUNT(*),
2
) AS placement_rate
FROM student_performance
GROUP BY program;

SELECT '--- 5. Ranking Students Within Departments ---';
SELECT
student_id,
name,
department,
gpa,
RANK()
OVER(
PARTITION BY department
ORDER BY gpa DESC
) AS department_rank
FROM student_performance
LIMIT 50;
