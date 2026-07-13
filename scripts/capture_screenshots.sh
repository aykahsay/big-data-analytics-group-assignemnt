#!/bin/bash
# =============================================================================
# capture_screenshots.sh
# Run this INSIDE your WSL/Ubuntu terminal:
#   bash /mnt/c/bigdata/big-data-analytics-group-assignemnt/scripts/capture_screenshots.sh
# =============================================================================

export HADOOP_HOME=/opt/hadoop
export HIVE_HOME=/opt/hive
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export PATH=$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$HIVE_HOME/bin:$PATH

PROJECT="/mnt/c/bigdata/big-data-analytics-group-assignemnt"
IMAGES="$PROJECT/images"
DATA="$PROJECT/data/EmployeeDataset.csv"
LOG="$PROJECT/employee_analysis_output.log"

mkdir -p "$IMAGES"

echo ""
echo "██████████████████████████████████████████████████████████████"
echo "  BIG DATA ANALYTICS — Employee Dataset Full Pipeline Runner"
echo "██████████████████████████████████████████████████████████████"
echo ""

# ─────────────────────────────────────────────────────────
# STEP 0: Start HDFS + YARN
# ─────────────────────────────────────────────────────────
echo "══════════════════════════════════════════════════"
echo "  [STEP 0] Starting Hadoop Services (HDFS + YARN)"
echo "══════════════════════════════════════════════════"
start-dfs.sh
sleep 6
start-yarn.sh
sleep 4

# ─────────────────────────────────────────────────────────
# STEP 1: Upload Dataset to HDFS  ← SCREENSHOT: hdfs_upload.png
# ─────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════"
echo "  [STEP 1] Uploading EmployeeDataset.csv → HDFS"
echo "  >>> SCREENSHOT THIS OUTPUT as: images/hdfs_upload.png"
echo "══════════════════════════════════════════════════"
hdfs dfs -mkdir -p /data/employee
hdfs dfs -put -f "$DATA" /data/employee/EmployeeDataset.csv
echo "--- Verify ---"
hdfs dfs -ls /data/employee/
hdfs dfs -du -h /data/employee/EmployeeDataset.csv

echo ""
echo "  *** TAKE SCREENSHOT NOW → save as: images/hdfs_upload.png ***"
read -p "  Press ENTER to continue to next step..."

# ─────────────────────────────────────────────────────────
# STEP 2: Create Raw Table  ← SCREENSHOT: raw_table_load.png
# ─────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════"
echo "  [STEP 2] Creating Raw Staging Table (emp_raw)"
echo "  >>> SCREENSHOT as: images/raw_table_load.png"
echo "══════════════════════════════════════════════════"
hive --hiveconf hive.exec.mode.local.auto=true \
     --hiveconf mapreduce.task.io.sort.mb=32 \
     -e "
DROP TABLE IF EXISTS emp_raw;
CREATE TABLE emp_raw (
    job_id STRING, job_title STRING, experience_years STRING,
    education_level STRING, skills_count STRING, industry STRING,
    company_size STRING, location STRING, remote_work STRING,
    call_log STRING, salary STRING, date_of_marriage STRING
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
STORED AS TEXTFILE
TBLPROPERTIES ('skip.header.line.count'='1');
LOAD DATA INPATH '/data/employee/EmployeeDataset.csv' INTO TABLE emp_raw;
SELECT 'Table emp_raw created successfully' AS status;
SELECT COUNT(*) AS total_rows FROM emp_raw;
SELECT * FROM emp_raw LIMIT 5;
" 2>/dev/null

echo ""
echo "  *** TAKE SCREENSHOT NOW → save as: images/raw_table_load.png ***"
read -p "  Press ENTER to continue..."

# ─────────────────────────────────────────────────────────
# PREPROCESSING PROBLEM 1: Missing experience_years
# ─────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════"
echo "  [PROBLEM 1] Missing Values in experience_years"
echo "  >>> SCREENSHOT as: images/missing_experience.png"
echo "══════════════════════════════════════════════════"
hive --hiveconf hive.exec.mode.local.auto=true \
     --hiveconf mapreduce.task.io.sort.mb=32 \
     -e "
SELECT job_id, job_title, experience_years, education_level
FROM emp_raw
WHERE experience_years IS NULL OR TRIM(experience_years) = '';
" 2>/dev/null

echo ""
echo "  *** TAKE SCREENSHOT NOW → save as: images/missing_experience.png ***"
read -p "  Press ENTER to continue..."

# ─────────────────────────────────────────────────────────
# PREPROCESSING PROBLEM 2: Duplicate job_ids
# ─────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════"
echo "  [PROBLEM 2] Duplicate job_id Values"
echo "  >>> SCREENSHOT as: images/duplicate_jobids.png"
echo "══════════════════════════════════════════════════"
hive --hiveconf hive.exec.mode.local.auto=true \
     --hiveconf mapreduce.task.io.sort.mb=32 \
     -e "
SELECT job_id, COUNT(*) AS cnt
FROM emp_raw
GROUP BY job_id
HAVING COUNT(*) > 1
ORDER BY cnt DESC;
" 2>/dev/null

echo ""
echo "  *** TAKE SCREENSHOT NOW → save as: images/duplicate_jobids.png ***"
read -p "  Press ENTER to continue..."

# ─────────────────────────────────────────────────────────
# PREPROCESSING PROBLEM 3: Inconsistent casing
# ─────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════"
echo "  [PROBLEM 3] Inconsistent Casing in education_level"
echo "  >>> SCREENSHOT as: images/inconsistent_casing.png"
echo "══════════════════════════════════════════════════"
hive --hiveconf hive.exec.mode.local.auto=true \
     --hiveconf mapreduce.task.io.sort.mb=32 \
     -e "
SELECT DISTINCT education_level FROM emp_raw ORDER BY education_level;
" 2>/dev/null

echo ""
echo "  *** TAKE SCREENSHOT NOW → save as: images/inconsistent_casing.png ***"
read -p "  Press ENTER to continue..."

# ─────────────────────────────────────────────────────────
# PREPROCESSING PROBLEM 4: Outlier salaries
# ─────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════"
echo "  [PROBLEM 4] Outlier Salary Values (< 1000)"
echo "  >>> SCREENSHOT as: images/outlier_salary.png"
echo "══════════════════════════════════════════════════"
hive --hiveconf hive.exec.mode.local.auto=true \
     --hiveconf mapreduce.task.io.sort.mb=32 \
     -e "
SELECT job_id, job_title, salary
FROM emp_raw
WHERE CAST(salary AS BIGINT) < 1000;
" 2>/dev/null

echo ""
echo "  *** TAKE SCREENSHOT NOW → save as: images/outlier_salary.png ***"
read -p "  Press ENTER to continue..."

# ─────────────────────────────────────────────────────────
# PREPROCESSING PROBLEM 5: Remote in location
# ─────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════"
echo "  [PROBLEM 5] 'Remote' Used as Location Value"
echo "  >>> SCREENSHOT as: images/remote_location.png"
echo "══════════════════════════════════════════════════"
hive --hiveconf hive.exec.mode.local.auto=true \
     --hiveconf mapreduce.task.io.sort.mb=32 \
     -e "
SELECT job_id, location, remote_work
FROM emp_raw
WHERE LOWER(TRIM(location)) = 'remote';
" 2>/dev/null

echo ""
echo "  *** TAKE SCREENSHOT NOW → save as: images/remote_location.png ***"
read -p "  Press ENTER to continue..."

# ─────────────────────────────────────────────────────────
# BUILD CLEANED TABLE
# ─────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════"
echo "  [CLEAN] Building emp_no_dup (all 5 fixes applied)"
echo "  >>> SCREENSHOT as: images/cleaned_table.png"
echo "══════════════════════════════════════════════════"
hive --hiveconf hive.exec.mode.local.auto=true \
     --hiveconf mapreduce.task.io.sort.mb=32 \
     -e "
DROP TABLE IF EXISTS emp_clean;
DROP TABLE IF EXISTS emp_no_dup;

CREATE TABLE emp_clean STORED AS ORC TBLPROPERTIES ('orc.compress'='SNAPPY') AS
SELECT
    job_id, job_title,
    CAST(COALESCE(NULLIF(TRIM(experience_years),''),'0') AS INT) AS experience_years,
    INITCAP(LOWER(TRIM(education_level))) AS education_level,
    CAST(skills_count AS INT) AS skills_count,
    industry, company_size,
    CASE WHEN LOWER(TRIM(location))='remote' THEN 'Unknown' ELSE TRIM(location) END AS location,
    CASE WHEN LOWER(TRIM(location))='remote' THEN 'Yes' ELSE TRIM(remote_work) END AS remote_work,
    CAST(call_log AS INT) AS call_log,
    CASE WHEN CAST(salary AS BIGINT)<1000 THEN NULL ELSE CAST(salary AS BIGINT) END AS salary,
    TRIM(date_of_marriage) AS date_of_marriage,
    ROW_NUMBER() OVER (PARTITION BY job_id ORDER BY job_id) AS rn
FROM emp_raw;

CREATE TABLE emp_no_dup STORED AS ORC TBLPROPERTIES ('orc.compress'='SNAPPY') AS
SELECT job_id, job_title, experience_years, education_level,
       skills_count, industry, company_size, location, remote_work,
       call_log, salary, date_of_marriage
FROM emp_clean WHERE rn = 1;

SELECT 'Cleaned rows:' AS label, COUNT(*) AS count FROM emp_no_dup;
SELECT * FROM emp_no_dup LIMIT 10;
" 2>/dev/null

echo ""
echo "  *** TAKE SCREENSHOT NOW → save as: images/cleaned_table.png ***"
read -p "  Press ENTER to continue..."

# ─────────────────────────────────────────────────────────
# TASK 2: Split job_title
# ─────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════"
echo "  [TASK 2] Split job_title → first_title_word + remaining_title"
echo "  >>> SCREENSHOT as: images/split_title.png"
echo "══════════════════════════════════════════════════"
hive --hiveconf hive.exec.mode.local.auto=true \
     --hiveconf mapreduce.task.io.sort.mb=32 \
     -e "
DROP TABLE IF EXISTS emp_split_title;
CREATE TABLE emp_split_title STORED AS ORC TBLPROPERTIES ('orc.compress'='SNAPPY') AS
SELECT
    job_id, job_title,
    SPLIT(TRIM(job_title), ' ')[0] AS first_title_word,
    REGEXP_REPLACE(TRIM(job_title), CONCAT('^', SPLIT(TRIM(job_title),' ')[0], ' ?'), '') AS remaining_title,
    experience_years, education_level, skills_count, location, call_log, salary
FROM emp_no_dup;

SELECT job_id, job_title, first_title_word, remaining_title
FROM emp_split_title LIMIT 20;
" 2>/dev/null

echo ""
echo "  *** TAKE SCREENSHOT NOW → save as: images/split_title.png ***"
read -p "  Press ENTER to continue..."

# ─────────────────────────────────────────────────────────
# TASK 3: PhD < 10 years by country
# ─────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════"
echo "  [TASK 3] PhD < 10 Years Experience by Country"
echo "  >>> SCREENSHOT as: images/phd_experience_country.png"
echo "══════════════════════════════════════════════════"
hive --hiveconf hive.exec.mode.local.auto=true \
     --hiveconf mapreduce.task.io.sort.mb=32 \
     -e "
SELECT location AS country, COUNT(*) AS phd_under_10yrs_count
FROM emp_no_dup
WHERE LOWER(TRIM(education_level)) = 'phd'
  AND experience_years < 10
GROUP BY location
ORDER BY phd_under_10yrs_count DESC;
" 2>/dev/null

echo ""
echo "  *** TAKE SCREENSHOT NOW → save as: images/phd_experience_country.png ***"
read -p "  Press ENTER to continue..."

# ─────────────────────────────────────────────────────────
# TASK 4: Skills count ascending
# ─────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════"
echo "  [TASK 4] Skills Count in Ascending Order"
echo "  >>> SCREENSHOT as: images/skills_count_asc.png"
echo "══════════════════════════════════════════════════"
hive --hiveconf hive.exec.mode.local.auto=true \
     --hiveconf mapreduce.task.io.sort.mb=32 \
     -e "
SELECT job_id, job_title, education_level, skills_count
FROM emp_no_dup
ORDER BY skills_count ASC;
" 2>/dev/null

echo ""
echo "  *** TAKE SCREENSHOT NOW → save as: images/skills_count_asc.png ***"
read -p "  Press ENTER to continue..."

# ─────────────────────────────────────────────────────────
# TASK 5: Growth Rate
# ─────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════"
echo "  [TASK 5a] Growth Rate of call_log (row-by-row)"
echo "  >>> SCREENSHOT as: images/growth_rate_detail.png"
echo "══════════════════════════════════════════════════"
hive --hiveconf hive.exec.mode.local.auto=true \
     --hiveconf mapreduce.task.io.sort.mb=32 \
     -e "
SELECT
    education_level, job_id, call_log AS current_call_log,
    LAG(call_log) OVER (PARTITION BY education_level ORDER BY job_id) AS prev_call_log,
    ROUND(
        CASE WHEN LAG(call_log) OVER (PARTITION BY education_level ORDER BY job_id) IS NULL
              OR LAG(call_log) OVER (PARTITION BY education_level ORDER BY job_id) = 0 THEN NULL
             ELSE ((call_log - LAG(call_log) OVER (PARTITION BY education_level ORDER BY job_id))
                   / CAST(LAG(call_log) OVER (PARTITION BY education_level ORDER BY job_id) AS DOUBLE)) * 100.0
        END, 2) AS growth_rate_pct
FROM emp_no_dup
WHERE LOWER(TRIM(education_level)) IN ('phd','bachelor','high school')
ORDER BY education_level, job_id;
" 2>/dev/null

echo ""
echo "  *** TAKE SCREENSHOT NOW → save as: images/growth_rate_detail.png ***"
read -p "  Press ENTER to continue..."

echo ""
echo "══════════════════════════════════════════════════"
echo "  [TASK 5b] Average Growth Rate Summary"
echo "  >>> SCREENSHOT as: images/growth_rate_summary.png"
echo "══════════════════════════════════════════════════"
hive --hiveconf hive.exec.mode.local.auto=true \
     --hiveconf mapreduce.task.io.sort.mb=32 \
     -e "
SELECT education_level, ROUND(AVG(gr), 2) AS avg_growth_rate_pct
FROM (
  SELECT education_level,
    CASE WHEN LAG(call_log) OVER (PARTITION BY education_level ORDER BY job_id) IS NULL
          OR LAG(call_log) OVER (PARTITION BY education_level ORDER BY job_id) = 0 THEN NULL
         ELSE ((call_log - LAG(call_log) OVER (PARTITION BY education_level ORDER BY job_id))
               / CAST(LAG(call_log) OVER (PARTITION BY education_level ORDER BY job_id) AS DOUBLE)) * 100.0
    END AS gr
  FROM emp_no_dup
  WHERE LOWER(TRIM(education_level)) IN ('phd','bachelor','high school')
) t
GROUP BY education_level
ORDER BY education_level;
" 2>/dev/null

echo ""
echo "  *** TAKE SCREENSHOT NOW → save as: images/growth_rate_summary.png ***"
read -p "  Press ENTER to continue..."

# ─────────────────────────────────────────────────────────
# TASK 6: Future Prediction
# ─────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════"
echo "  [TASK 6] Predict Future call_log Values"
echo "  >>> SCREENSHOT as: images/future_prediction.png"
echo "══════════════════════════════════════════════════"
hive --hiveconf hive.exec.mode.local.auto=true \
     --hiveconf mapreduce.task.io.sort.mb=32 \
     -e "
WITH gs AS (
  SELECT education_level, job_id, call_log,
    LAG(call_log) OVER (PARTITION BY education_level ORDER BY job_id) AS prev
  FROM emp_no_dup
  WHERE LOWER(TRIM(education_level)) IN ('phd','bachelor','high school')
),
gp AS (
  SELECT education_level, call_log,
    CASE WHEN prev IS NULL OR prev=0 THEN NULL
         ELSE ((call_log-prev)/CAST(prev AS DOUBLE))*100.0 END AS gr
  FROM gs
),
sm AS (
  SELECT education_level,
    COUNT(*) AS n, ROUND(AVG(call_log),2) AS avg_cl,
    MAX(call_log) AS last_cl, ROUND(AVG(gr),4) AS avg_gr
  FROM gp GROUP BY education_level
)
SELECT education_level, n AS records, avg_cl AS avg_call_log,
       last_cl AS last_call_log, ROUND(avg_gr,2) AS avg_growth_pct,
       ROUND(last_cl*POWER(1+avg_gr/100.0,1),2) AS predicted_period_1,
       ROUND(last_cl*POWER(1+avg_gr/100.0,2),2) AS predicted_period_2,
       ROUND(last_cl*POWER(1+avg_gr/100.0,3),2) AS predicted_period_3
FROM sm ORDER BY education_level;
" 2>/dev/null

echo ""
echo "  *** TAKE SCREENSHOT NOW → save as: images/future_prediction.png ***"
echo ""
echo "██████████████████████████████████████████████████████████████"
echo "  ALL DONE! Screenshots saved to: $IMAGES"
echo "  Now compile the LaTeX report:"
echo "    pdflatex /mnt/c/bigdata/big-data-analytics-group-assignemnt/project_report.tex"
echo "██████████████████████████████████████████████████████████████"
