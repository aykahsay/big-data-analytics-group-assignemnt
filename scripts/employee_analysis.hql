-- =============================================================================
-- File   : employee_analysis.hql
-- Purpose: Full Hadoop/Hive analysis of EmployeeDataset.csv
-- Tasks  :
--   1. Upload & create raw staging table
--   2. Identify and fix five data preprocessing problems
--   3. Split job_title into first_title_word and remaining_title
--   4. Count PhDs with < 10 years experience by country
--   5. Display skills_count in ascending order
--   6. Calculate Growth Rate of call_log for PhD / Bachelor / High School
--   7. Predict Future Value of call_log for PhD / Bachelor / High School
-- =============================================================================

-- Tune memory for local / pseudo-distributed mode
SET mapreduce.task.io.sort.mb=32;
SET hive.exec.mode.local.auto=true;

-- ============================================================
-- SECTION 0 – DROP ALL WORKING TABLES (clean re-run)
-- ============================================================
DROP TABLE IF EXISTS emp_raw;
DROP TABLE IF EXISTS emp_no_dup;
DROP TABLE IF EXISTS emp_clean;
DROP TABLE IF EXISTS emp_split_title;

-- ============================================================
-- SECTION 1 – LOAD RAW DATA FROM HDFS (Staging Table)
-- ============================================================
SELECT '===== SECTION 1: LOAD RAW STAGING TABLE =====' AS section;

CREATE TABLE emp_raw (
    job_id            STRING,
    job_title         STRING,
    experience_years  STRING,   -- kept as STRING so NULLs survive load
    education_level   STRING,
    skills_count      STRING,
    industry          STRING,
    company_size      STRING,
    location          STRING,
    remote_work       STRING,
    call_log          STRING,
    salary            STRING,
    date_of_marriage  STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
TBLPROPERTIES ("skip.header.line.count"="1");

LOAD DATA INPATH '/data/employee/EmployeeDataset.csv'
INTO TABLE emp_raw;

SELECT '--- Raw row count ---' AS info;
SELECT COUNT(*) AS total_raw_rows FROM emp_raw;

SELECT '--- Preview (first 10 rows) ---' AS info;
SELECT * FROM emp_raw LIMIT 10;


-- ============================================================
-- SECTION 2 – DATA PREPROCESSING: IDENTIFY & FIX PROBLEMS
-- ============================================================
SELECT '===== SECTION 2: DATA PREPROCESSING =====' AS section;

-- ------------------------------------------------------------------
-- PROBLEM 1: MISSING VALUES in experience_years
-- ------------------------------------------------------------------
SELECT '--- Problem 1: Missing values in experience_years ---' AS problem;
SELECT job_id, job_title, experience_years, education_level
FROM emp_raw
WHERE experience_years IS NULL OR TRIM(experience_years) = '';

-- Fix: Replace NULLs / empty strings with the median (impute as 0)
-- We will carry the fix into the cleaned table below.

-- ------------------------------------------------------------------
-- PROBLEM 2: DUPLICATE JOB IDs (same job_id used for different roles)
-- ------------------------------------------------------------------
SELECT '--- Problem 2: Duplicate job_id values ---' AS problem;
SELECT job_id, COUNT(*) AS cnt
FROM emp_raw
GROUP BY job_id
HAVING COUNT(*) > 1
ORDER BY cnt DESC;

-- ------------------------------------------------------------------
-- PROBLEM 3: INCONSISTENT CASE in education_level
--            e.g. "high School", "bachelor", "PhD", "Bachelor"
-- ------------------------------------------------------------------
SELECT '--- Problem 3: Inconsistent casing in education_level ---' AS problem;
SELECT DISTINCT education_level FROM emp_raw ORDER BY education_level;

-- ------------------------------------------------------------------
-- PROBLEM 4: INVALID / OUTLIER VALUES in salary
--            Suspiciously low values (< 1000) suggest data entry errors
-- ------------------------------------------------------------------
SELECT '--- Problem 4: Outlier salary values (< 1000) ---' AS problem;
SELECT job_id, job_title, salary
FROM emp_raw
WHERE CAST(salary AS BIGINT) < 1000;

-- ------------------------------------------------------------------
-- PROBLEM 5: INVALID LOCATION ("Remote" mixed with country names)
--            "Remote" is a work-mode, not a country – normalise it
-- ------------------------------------------------------------------
SELECT '--- Problem 5: Location contains work-mode value "Remote" ---' AS problem;
SELECT job_id, location, remote_work
FROM emp_raw
WHERE LOWER(TRIM(location)) = 'remote';

-- -----------------------------------------------------------------------
-- BUILD CLEANED TABLE – applies all five fixes simultaneously:
--   Fix 1: COALESCE experience_years NULL/empty → 0
--   Fix 2: Use ROW_NUMBER to keep only the first occurrence per job_id
--   Fix 3: INITCAP on education_level normalises casing
--   Fix 4: Replace salary < 1000 with NULL (flagged for manual review)
--   Fix 5: Replace location='Remote' with 'Unknown' and set remote_work='Yes'
-- -----------------------------------------------------------------------
SELECT '--- Applying all fixes → emp_clean ---' AS info;

CREATE TABLE emp_clean
STORED AS ORC
TBLPROPERTIES ("orc.compress"="SNAPPY") AS
SELECT
    job_id,
    job_title,
    -- Fix 1: impute missing experience_years with 0
    CAST(COALESCE(NULLIF(TRIM(experience_years), ''), '0') AS INT) AS experience_years,
    -- Fix 3: normalise education_level casing
    INITCAP(LOWER(TRIM(education_level)))                          AS education_level,
    CAST(skills_count AS INT)                                      AS skills_count,
    industry,
    company_size,
    -- Fix 5: replace 'Remote' location → 'Unknown'
    CASE
        WHEN LOWER(TRIM(location)) = 'remote' THEN 'Unknown'
        ELSE TRIM(location)
    END                                                            AS location,
    -- Fix 5: ensure remote_work is 'Yes' when location was 'Remote'
    CASE
        WHEN LOWER(TRIM(location)) = 'remote' THEN 'Yes'
        ELSE TRIM(remote_work)
    END                                                            AS remote_work,
    CAST(call_log AS INT)                                          AS call_log,
    -- Fix 4: null out implausibly low salaries
    CASE
        WHEN CAST(salary AS BIGINT) < 1000 THEN NULL
        ELSE CAST(salary AS BIGINT)
    END                                                            AS salary,
    TRIM(date_of_marriage)                                         AS date_of_marriage,
    -- Fix 2: row number for deduplication by job_id
    ROW_NUMBER() OVER (PARTITION BY job_id ORDER BY job_id)        AS rn
FROM emp_raw;

-- Keep only first occurrence per job_id (Fix 2)
CREATE TABLE emp_no_dup
STORED AS ORC
TBLPROPERTIES ("orc.compress"="SNAPPY") AS
SELECT
    job_id, job_title, experience_years, education_level,
    skills_count, industry, company_size, location, remote_work,
    call_log, salary, date_of_marriage
FROM emp_clean
WHERE rn = 1;

SELECT '--- Cleaned row count (after deduplication) ---' AS info;
SELECT COUNT(*) AS total_cleaned_rows FROM emp_no_dup;

SELECT '--- Preview cleaned data (10 rows) ---' AS info;
SELECT * FROM emp_no_dup LIMIT 10;

SELECT '--- Verify education_level after normalisation ---' AS info;
SELECT DISTINCT education_level FROM emp_no_dup ORDER BY education_level;

SELECT '--- Verify salary fix (no values < 1000 remain) ---' AS info;
SELECT COUNT(*) AS low_salary_count FROM emp_no_dup WHERE salary < 1000;

SELECT '--- Verify location fix (no "Remote" in location column) ---' AS info;
SELECT COUNT(*) AS remote_in_location
FROM emp_no_dup
WHERE LOWER(location) = 'remote';


-- ============================================================
-- SECTION 3 – SPLIT JOB TITLE
-- ============================================================
SELECT '===== SECTION 3: SPLIT JOB TITLE =====' AS section;
-- job_title examples: "AI Engineer", "Machine Learning Engineer",
--   "Frontend Developer", "Data Scientist", etc.
-- We split on the FIRST space:
--   first_title_word  → first token  (e.g. "AI", "Machine", "Frontend")
--   remaining_title   → everything after the first space (the "others")

CREATE TABLE emp_split_title
STORED AS ORC
TBLPROPERTIES ("orc.compress"="SNAPPY") AS
SELECT
    job_id,
    job_title,
    -- First word (up to first space)
    SPLIT(TRIM(job_title), ' ')[0]                                 AS first_title_word,
    -- Everything after the first space (index 1 onward joined back)
    REGEXP_REPLACE(TRIM(job_title),
                   CONCAT('^', SPLIT(TRIM(job_title), ' ')[0], ' ?'), '')
                                                                   AS remaining_title,
    experience_years,
    education_level,
    skills_count,
    industry,
    company_size,
    location,
    remote_work,
    call_log,
    salary,
    date_of_marriage
FROM emp_no_dup;

SELECT '--- Split job title preview ---' AS info;
SELECT job_id, job_title, first_title_word, remaining_title
FROM emp_split_title
LIMIT 20;


-- ============================================================
-- SECTION 4 – COUNT PhDs WITH < 10 YEARS EXPERIENCE BY COUNTRY
-- ============================================================
SELECT '===== SECTION 4: PhDs with < 10 Years Experience by Country =====' AS section;

SELECT
    location                    AS country,
    COUNT(*)                    AS phd_under_10yrs_count
FROM emp_no_dup
WHERE LOWER(TRIM(education_level)) = 'phd'
  AND experience_years < 10
GROUP BY location
ORDER BY phd_under_10yrs_count DESC;

-- Total count
SELECT
    COUNT(*) AS total_phd_less_than_10yrs
FROM emp_no_dup
WHERE LOWER(TRIM(education_level)) = 'phd'
  AND experience_years < 10;


-- ============================================================
-- SECTION 5 – SKILLS COUNT IN ASCENDING ORDER
-- ============================================================
SELECT '===== SECTION 5: Skills Count in Ascending Order =====' AS section;

SELECT
    job_id,
    job_title,
    education_level,
    skills_count
FROM emp_no_dup
ORDER BY skills_count ASC;

-- Summary: frequency distribution of skills_count values
SELECT
    skills_count,
    COUNT(*) AS frequency
FROM emp_no_dup
GROUP BY skills_count
ORDER BY skills_count ASC;


-- ============================================================
-- SECTION 6 – GROWTH RATE OF CALL LOG (PhD / Bachelor / High School)
-- ============================================================
-- Growth Rate = ((Current - Previous) / Previous) * 100
-- We treat each job_id row as a sequential data point ordered by job_id.
-- For each education group, we compute row-to-row growth in call_log.
SELECT '===== SECTION 6: Growth Rate of Call Log =====' AS section;

-- Aggregate call_log by education group, then compute growth rate
-- between consecutive rows (ordered by job_id) within each group.

SELECT
    education_level,
    job_id,
    call_log                                                   AS current_call_log,
    LAG(call_log) OVER (
        PARTITION BY education_level
        ORDER BY job_id
    )                                                          AS prev_call_log,
    ROUND(
        CASE
            WHEN LAG(call_log) OVER (
                     PARTITION BY education_level ORDER BY job_id
                 ) IS NULL
              OR LAG(call_log) OVER (
                     PARTITION BY education_level ORDER BY job_id
                 ) = 0
            THEN NULL
            ELSE ((call_log - LAG(call_log) OVER (
                                  PARTITION BY education_level ORDER BY job_id
                              ))
                  / CAST(LAG(call_log) OVER (
                              PARTITION BY education_level ORDER BY job_id
                         ) AS DOUBLE)) * 100.0
        END
    , 2)                                                       AS growth_rate_pct
FROM emp_no_dup
WHERE LOWER(TRIM(education_level)) IN ('phd', 'bachelor', 'high school')
ORDER BY education_level, job_id;

-- Summary: Average growth rate per education level
SELECT
    education_level,
    ROUND(AVG(growth_rate_pct), 2)  AS avg_growth_rate_pct
FROM (
    SELECT
        education_level,
        ROUND(
            CASE
                WHEN LAG(call_log) OVER (
                         PARTITION BY education_level ORDER BY job_id
                     ) IS NULL
                  OR LAG(call_log) OVER (
                         PARTITION BY education_level ORDER BY job_id
                     ) = 0
                THEN NULL
                ELSE ((call_log - LAG(call_log) OVER (
                                      PARTITION BY education_level ORDER BY job_id
                                  ))
                      / CAST(LAG(call_log) OVER (
                                  PARTITION BY education_level ORDER BY job_id
                             ) AS DOUBLE)) * 100.0
            END
        , 2) AS growth_rate_pct
    FROM emp_no_dup
    WHERE LOWER(TRIM(education_level)) IN ('phd', 'bachelor', 'high school')
) growth_sub
GROUP BY education_level
ORDER BY education_level;


-- ============================================================
-- SECTION 7 – PREDICT FUTURE VALUE OF CALL LOG
-- ============================================================
-- Formula used: Linear Trend Prediction
--   Future Value = Last Value * (1 + avg_growth_rate / 100) ^ n_periods
-- We predict 3 steps ahead for each education group.
-- avg_growth_rate is computed from the historical data above.
SELECT '===== SECTION 7: Predicted Future Call Log Values =====' AS section;

WITH growth_stats AS (
    -- Step A: compute row-to-row growth rates
    SELECT
        education_level,
        job_id,
        call_log,
        LAG(call_log) OVER (
            PARTITION BY education_level ORDER BY job_id
        ) AS prev_call_log
    FROM emp_no_dup
    WHERE LOWER(TRIM(education_level)) IN ('phd', 'bachelor', 'high school')
),
growth_pct AS (
    -- Step B: growth % per row
    SELECT
        education_level,
        job_id,
        call_log,
        CASE
            WHEN prev_call_log IS NULL OR prev_call_log = 0 THEN NULL
            ELSE ((call_log - prev_call_log)
                  / CAST(prev_call_log AS DOUBLE)) * 100.0
        END AS growth_rate_pct
    FROM growth_stats
),
summary AS (
    -- Step C: aggregate stats per education group
    SELECT
        education_level,
        COUNT(*)                          AS n_records,
        ROUND(AVG(call_log), 4)           AS avg_call_log,
        MAX(call_log)                     AS last_call_log,
        ROUND(AVG(growth_rate_pct), 4)    AS avg_growth_rate_pct
    FROM growth_pct
    GROUP BY education_level
)
-- Step D: project 1, 2 and 3 periods ahead using compound growth formula
SELECT
    education_level,
    n_records,
    avg_call_log,
    last_call_log,
    ROUND(avg_growth_rate_pct, 2)                                       AS avg_growth_rate_pct,
    ROUND(last_call_log
          * POWER(1 + avg_growth_rate_pct / 100.0, 1), 4)               AS predicted_period_1,
    ROUND(last_call_log
          * POWER(1 + avg_growth_rate_pct / 100.0, 2), 4)               AS predicted_period_2,
    ROUND(last_call_log
          * POWER(1 + avg_growth_rate_pct / 100.0, 3), 4)               AS predicted_period_3
FROM summary
ORDER BY education_level;

-- ============================================================
-- END OF SCRIPT
-- ============================================================
SELECT '===== ALL SECTIONS COMPLETE =====' AS done;
