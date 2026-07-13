#!/bin/bash
# ============================================================
# run_all_queries.sh
# Save all Hive query outputs to text files in images/ folder
# Then Python converts them to PNG screenshots
# Run: bash /mnt/c/bigdata/big-data-analytics-group-assignemnt/scripts/run_all_queries.sh
# ============================================================

export HADOOP_HOME=/opt/hadoop
export HIVE_HOME=/opt/hive
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export PATH=$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$HIVE_HOME/bin:$PATH

PROJECT="/mnt/c/bigdata/big-data-analytics-group-assignemnt"
IMAGES="$PROJECT/images"
DATA="$PROJECT/data/EmployeeDataset.csv"

mkdir -p "$IMAGES"

HIVE_OPTS="--hiveconf hive.exec.mode.local.auto=true --hiveconf mapreduce.task.io.sort.mb=32"

echo "=== [0] Starting HDFS + YARN ==="
/opt/hadoop/sbin/start-dfs.sh 2>&1
sleep 6
/opt/hadoop/sbin/start-yarn.sh 2>&1
sleep 4

echo "=== [1] Upload to HDFS ==="
hdfs dfs -mkdir -p /data/employee 2>&1
hdfs dfs -put -f "$DATA" /data/employee/EmployeeDataset.csv 2>&1
hdfs dfs -ls /data/employee/ 2>&1 | tee "$IMAGES/01_hdfs_upload.txt"

echo "=== [2] Create Raw Table ==="
hive $HIVE_OPTS -e "
DROP TABLE IF EXISTS emp_raw;
CREATE TABLE emp_raw (job_id STRING, job_title STRING, experience_years STRING, education_level STRING, skills_count STRING, industry STRING, company_size STRING, location STRING, remote_work STRING, call_log STRING, salary STRING, date_of_marriage STRING)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' STORED AS TEXTFILE TBLPROPERTIES ('skip.header.line.count'='1');
LOAD DATA INPATH '/data/employee/EmployeeDataset.csv' INTO TABLE emp_raw;
SELECT 'emp_raw created - row count:' AS status;
SELECT COUNT(*) AS total FROM emp_raw;
SELECT * FROM emp_raw LIMIT 8;
" 2>/dev/null | tee "$IMAGES/02_raw_table_load.txt"

echo "=== [3] Problem 1: Missing experience_years ==="
hive $HIVE_OPTS -e "
SELECT '==== PROBLEM 1: Missing Values in experience_years ====' AS title;
SELECT job_id, job_title, experience_years, education_level
FROM emp_raw WHERE experience_years IS NULL OR TRIM(experience_years) = '';
" 2>/dev/null | tee "$IMAGES/03_missing_experience.txt"

echo "=== [4] Problem 2: Duplicate job_ids ==="
hive $HIVE_OPTS -e "
SELECT '==== PROBLEM 2: Duplicate job_id Values ====' AS title;
SELECT job_id, COUNT(*) AS cnt FROM emp_raw GROUP BY job_id HAVING COUNT(*) > 1 ORDER BY cnt DESC;
" 2>/dev/null | tee "$IMAGES/04_duplicate_jobids.txt"

echo "=== [5] Problem 3: Inconsistent casing ==="
hive $HIVE_OPTS -e "
SELECT '==== PROBLEM 3: Inconsistent Casing in education_level ====' AS title;
SELECT DISTINCT education_level FROM emp_raw ORDER BY education_level;
" 2>/dev/null | tee "$IMAGES/05_inconsistent_casing.txt"

echo "=== [6] Problem 4: Outlier salaries ==="
hive $HIVE_OPTS -e "
SELECT '==== PROBLEM 4: Outlier Salary Values (< 1000) ====' AS title;
SELECT job_id, job_title, salary FROM emp_raw WHERE CAST(salary AS BIGINT) < 1000;
" 2>/dev/null | tee "$IMAGES/06_outlier_salary.txt"

echo "=== [7] Problem 5: Remote in location ==="
hive $HIVE_OPTS -e "
SELECT '==== PROBLEM 5: Remote Used as Location Value ====' AS title;
SELECT job_id, location, remote_work FROM emp_raw WHERE LOWER(TRIM(location)) = 'remote';
" 2>/dev/null | tee "$IMAGES/07_remote_location.txt"

echo "=== [8] Build Cleaned Table ==="
hive $HIVE_OPTS -e "
DROP TABLE IF EXISTS emp_clean; DROP TABLE IF EXISTS emp_no_dup;
CREATE TABLE emp_clean STORED AS ORC TBLPROPERTIES ('orc.compress'='SNAPPY') AS
SELECT job_id, job_title,
  CAST(COALESCE(NULLIF(TRIM(experience_years),''),'0') AS INT) AS experience_years,
  INITCAP(LOWER(TRIM(education_level))) AS education_level,
  CAST(skills_count AS INT) AS skills_count, industry, company_size,
  CASE WHEN LOWER(TRIM(location))='remote' THEN 'Unknown' ELSE TRIM(location) END AS location,
  CASE WHEN LOWER(TRIM(location))='remote' THEN 'Yes' ELSE TRIM(remote_work) END AS remote_work,
  CAST(call_log AS INT) AS call_log,
  CASE WHEN CAST(salary AS BIGINT)<1000 THEN NULL ELSE CAST(salary AS BIGINT) END AS salary,
  TRIM(date_of_marriage) AS date_of_marriage,
  ROW_NUMBER() OVER (PARTITION BY job_id ORDER BY job_id) AS rn
FROM emp_raw;
CREATE TABLE emp_no_dup STORED AS ORC TBLPROPERTIES ('orc.compress'='SNAPPY') AS
SELECT job_id, job_title, experience_years, education_level, skills_count, industry, company_size, location, remote_work, call_log, salary, date_of_marriage
FROM emp_clean WHERE rn = 1;
SELECT '==== CLEANED TABLE (emp_no_dup) - All 5 Fixes Applied ====' AS title;
SELECT COUNT(*) AS cleaned_row_count FROM emp_no_dup;
SELECT * FROM emp_no_dup LIMIT 10;
" 2>/dev/null | tee "$IMAGES/08_cleaned_table.txt"

echo "=== [9] Task 2: Split job_title ==="
hive $HIVE_OPTS -e "
DROP TABLE IF EXISTS emp_split_title;
CREATE TABLE emp_split_title STORED AS ORC TBLPROPERTIES ('orc.compress'='SNAPPY') AS
SELECT job_id, job_title,
  SPLIT(TRIM(job_title),' ')[0] AS first_title_word,
  REGEXP_REPLACE(TRIM(job_title), CONCAT('^', SPLIT(TRIM(job_title),' ')[0], ' ?'), '') AS remaining_title,
  education_level, experience_years, skills_count, call_log
FROM emp_no_dup;
SELECT '==== TASK 2: Split job_title into first_title_word + remaining_title ====' AS title;
SELECT job_id, job_title, first_title_word, remaining_title FROM emp_split_title LIMIT 20;
" 2>/dev/null | tee "$IMAGES/09_split_title.txt"

echo "=== [10] Task 3: PhD < 10 yrs by country ==="
hive $HIVE_OPTS -e "
SELECT '==== TASK 3: PhD Holders with < 10 Years Experience by Country ====' AS title;
SELECT location AS country, COUNT(*) AS phd_under_10yrs_count
FROM emp_no_dup
WHERE LOWER(TRIM(education_level)) = 'phd' AND experience_years < 10
GROUP BY location ORDER BY phd_under_10yrs_count DESC;
" 2>/dev/null | tee "$IMAGES/10_phd_experience_country.txt"

echo "=== [11] Task 4: Skills count ascending ==="
hive $HIVE_OPTS -e "
SELECT '==== TASK 4: Skills Count in Ascending Order ====' AS title;
SELECT job_id, job_title, education_level, skills_count FROM emp_no_dup ORDER BY skills_count ASC;
" 2>/dev/null | tee "$IMAGES/11_skills_count_asc.txt"

echo "=== [12] Task 5a: Growth rate detail ==="
hive $HIVE_OPTS -e "
SELECT '==== TASK 5: Growth Rate of call_log (PhD, Bachelor, High School) ====' AS title;
SELECT education_level, job_id, call_log AS current_call_log,
  LAG(call_log) OVER (PARTITION BY education_level ORDER BY job_id) AS prev_call_log,
  ROUND(CASE WHEN LAG(call_log) OVER (PARTITION BY education_level ORDER BY job_id) IS NULL
              OR LAG(call_log) OVER (PARTITION BY education_level ORDER BY job_id) = 0 THEN NULL
             ELSE ((call_log - LAG(call_log) OVER (PARTITION BY education_level ORDER BY job_id))
                   / CAST(LAG(call_log) OVER (PARTITION BY education_level ORDER BY job_id) AS DOUBLE)) * 100.0
        END, 2) AS growth_rate_pct
FROM emp_no_dup
WHERE LOWER(TRIM(education_level)) IN ('phd','bachelor','high school')
ORDER BY education_level, job_id;
" 2>/dev/null | tee "$IMAGES/12_growth_rate_detail.txt"

echo "=== [13] Task 5b: Growth rate summary ==="
hive $HIVE_OPTS -e "
SELECT '==== TASK 5 SUMMARY: Average Growth Rate per Education Level ====' AS title;
SELECT education_level, ROUND(AVG(gr),2) AS avg_growth_rate_pct
FROM (
  SELECT education_level,
    CASE WHEN LAG(call_log) OVER (PARTITION BY education_level ORDER BY job_id) IS NULL
          OR LAG(call_log) OVER (PARTITION BY education_level ORDER BY job_id) = 0 THEN NULL
         ELSE ((call_log - LAG(call_log) OVER (PARTITION BY education_level ORDER BY job_id))
               / CAST(LAG(call_log) OVER (PARTITION BY education_level ORDER BY job_id) AS DOUBLE)) * 100.0
    END AS gr
  FROM emp_no_dup
  WHERE LOWER(TRIM(education_level)) IN ('phd','bachelor','high school')
) t GROUP BY education_level ORDER BY education_level;
" 2>/dev/null | tee "$IMAGES/13_growth_rate_summary.txt"

echo "=== [14] Task 6: Future Prediction ==="
hive $HIVE_OPTS -e "
SELECT '==== TASK 6: Predicted Future call_log Values (Compound Growth Model) ====' AS title;
WITH gs AS (
  SELECT education_level, job_id, call_log,
    LAG(call_log) OVER (PARTITION BY education_level ORDER BY job_id) AS prev
  FROM emp_no_dup WHERE LOWER(TRIM(education_level)) IN ('phd','bachelor','high school')
),
gp AS (
  SELECT education_level, call_log,
    CASE WHEN prev IS NULL OR prev=0 THEN NULL
         ELSE ((call_log-prev)/CAST(prev AS DOUBLE))*100.0 END AS gr FROM gs
),
sm AS (
  SELECT education_level, COUNT(*) AS n, ROUND(AVG(call_log),2) AS avg_cl,
    MAX(call_log) AS last_cl, ROUND(AVG(gr),4) AS avg_gr FROM gp GROUP BY education_level
)
SELECT education_level, n AS records, avg_cl AS avg_call_log, last_cl AS last_call_log,
  ROUND(avg_gr,2) AS avg_growth_pct,
  ROUND(last_cl*POWER(1+avg_gr/100.0,1),2) AS predicted_period_1,
  ROUND(last_cl*POWER(1+avg_gr/100.0,2),2) AS predicted_period_2,
  ROUND(last_cl*POWER(1+avg_gr/100.0,3),2) AS predicted_period_3
FROM sm ORDER BY education_level;
" 2>/dev/null | tee "$IMAGES/14_future_prediction.txt"

echo ""
echo "=== ALL DONE. Converting text outputs to PNG images... ==="
python3 "$PROJECT/scripts/txt_to_png.py" "$IMAGES"
echo "=== Screenshots saved to $IMAGES ==="
ls -la "$IMAGES"/*.png 2>/dev/null || echo "No PNGs yet - run txt_to_png.py manually"
