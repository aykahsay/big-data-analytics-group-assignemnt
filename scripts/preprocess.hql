-- Hive Data Preprocessing Practical Script
-- Database: default

-- Reduce memory buffers to prevent Java Heap Space OOM in local mode
SET mapreduce.task.io.sort.mb=10;

-- Drop existing tables for a clean run
DROP TABLE IF EXISTS raw_data;
DROP TABLE IF EXISTS no_duplicates;
DROP TABLE IF EXISTS cleaned_student_scores;

-- =========================================================================
-- STEP 1: Load Raw Data (Staging Table)
-- =========================================================================
CREATE TABLE raw_data (
    id STRING,
    name STRING,
    gender STRING,
    marks STRING,
    course STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
TBLPROPERTIES ("skip.header.line.count"="1");

-- Load data from HDFS path (uploaded from student_scores.csv)
LOAD DATA INPATH '/data/student_scores.csv' INTO TABLE raw_data;

-- =========================================================================
-- STEP 2: Explore the Data
-- =========================================================================
SELECT '--- STEP 2: RAW STAGING DATA ---' AS step;
SELECT * FROM raw_data;

-- =========================================================================
-- STEP 3: Handle Missing Values
-- =========================================================================
SELECT '--- STEP 3: MISSING MARKS ---' AS step;
-- Find rows with missing marks
SELECT * FROM raw_data WHERE marks IS NULL OR marks = '';

-- Replace missing marks with '0'
SELECT '--- STEP 3: REPLACED MISSING MARKS ---' AS step;
SELECT id, name, COALESCE(NULLIF(marks, ''), '0') AS marks FROM raw_data;

-- =========================================================================
-- STEP 4: Remove Duplicates
-- =========================================================================
SELECT '--- STEP 4: IDENTIFY DUPLICATES ---' AS step;
SELECT id, COUNT(*) FROM raw_data GROUP BY id HAVING COUNT(*) > 1;

-- Create table with no duplicates
CREATE TABLE no_duplicates AS
SELECT DISTINCT * FROM raw_data;

SELECT '--- STEP 4: DATA WITHOUT DUPLICATES ---' AS step;
SELECT * FROM no_duplicates;

-- =========================================================================
-- STEP 5: Fix Inconsistent Formats
-- =========================================================================
SELECT '--- STEP 5: STANDARDIZE TEXT ---' AS step;
SELECT id, UPPER(name) AS name, LOWER(course) AS course FROM raw_data;

SELECT '--- STEP 5: STANDARDIZE GENDER ---' AS step;
SELECT 
    id,
    name,
    CASE
        WHEN LOWER(gender) IN ('m', 'male') THEN 'Male'
        WHEN LOWER(gender) IN ('f', 'female') THEN 'Female'
        ELSE 'Unknown'
    END AS gender
FROM raw_data;

-- =========================================================================
-- STEP 6: Detect Noisy or Invalid Data
-- =========================================================================
SELECT '--- STEP 6: DETECT NOISY/INVALID MARKS ---' AS step;
-- Marks should be between 0 and 100. Let's find rows with out-of-range marks.
SELECT * FROM raw_data 
WHERE CAST(marks AS INT) < 0 OR CAST(marks AS INT) > 100;

-- =========================================================================
-- STEP 7: Create a Cleaned Dataset for Analysis
-- =========================================================================
-- Combines all cleaning steps:
-- - Uses DISTINCT to remove duplicate rows
-- - Uses COALESCE and NULLIF to treat missing marks as 0
-- - Converts names to UPPERCASE and courses to LOWERCASE
-- - Standardizes genders to 'Male' or 'Female'
-- - Filters out records with invalid marks (out of bounds)
-- - Saves as an optimized ORC table with Snappy compression for production performance
CREATE TABLE cleaned_student_scores
STORED AS ORC
TBLPROPERTIES ("orc.compress"="SNAPPY") AS
SELECT 
    id,
    UPPER(name) AS name,
    CASE
        WHEN LOWER(gender) IN ('m', 'male') THEN 'Male'
        WHEN LOWER(gender) IN ('f', 'female') THEN 'Female'
        ELSE 'Unknown'
    END AS gender,
    CAST(COALESCE(NULLIF(marks, ''), '0') AS INT) AS marks,
    LOWER(course) AS course
FROM (
    SELECT DISTINCT id, name, gender, marks, course FROM raw_data
) unique_rows
WHERE marks = '' OR (CAST(marks AS INT) BETWEEN 0 AND 100);

SELECT '--- STEP 7: FINAL CLEANED DATASET ---' AS step;
SELECT * FROM cleaned_student_scores;
