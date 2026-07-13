-- =============================================================================
-- File   : student_descriptive.hql
-- Purpose: Full Descriptive Analysis of BigData_Student_Performance_Dataset_1000
-- Dataset: /data/BigData_Student_Performance_Dataset_1000.csv (HDFS)
-- Sections:
--   0.  Setup & Table Creation
--   1.  Data Quality Checks
--   2.  Overall Summary Statistics
--   3.  Grade Distribution
--   4.  Department Analysis
--   5.  Gender Analysis
--   6.  Program Analysis (BSc vs MSc)
--   7.  Academic Performance (Attendance, CAT, FinalExam, Assignment)
--   8.  Engagement Metrics (LMSLogins, LibraryVisits, StudyHours)
--   9.  Socioeconomic Analysis (ParentIncome quintiles)
--   10. Technology Access (InternetAccess, Device)
--   11. Top & Bottom Performers
--   12. Location Analysis
--   13. Scholarship Impact
--   14. Window Functions – Rank within Department
-- =============================================================================

SET mapreduce.task.io.sort.mb=32;
SET hive.exec.mode.local.auto=true;
SET hive.auto.convert.join=true;
SET hive.vectorized.execution.enabled=true;

-- ============================================================
-- SECTION 0 – SETUP: DROP & CREATE DATABASE + TABLE
-- ============================================================
SELECT '=========================================' AS section_header;
SELECT '  SECTION 0: SETUP & TABLE CREATION     ' AS section_header;
SELECT '=========================================' AS section_header;

CREATE DATABASE IF NOT EXISTS student_analysis;
USE student_analysis;

DROP TABLE IF EXISTS student_perf_raw;
DROP TABLE IF EXISTS student_perf;

CREATE TABLE student_perf_raw (
    student_id     STRING,
    name           STRING,
    gender         STRING,
    age            STRING,
    department     STRING,
    program        STRING,
    year           STRING,
    semester       STRING,
    attendance     STRING,
    assignment     STRING,
    cat            STRING,
    finalexam      STRING,
    studyhours     STRING,
    internetaccess STRING,
    device         STRING,
    parentincome   STRING,
    scholarship    STRING,
    skillscount    STRING,
    projects       STRING,
    lmslogins      STRING,
    libraryvisits  STRING,
    location       STRING,
    graduated      STRING,
    placement      STRING,
    gpa            STRING,
    total          STRING,
    grade          STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
TBLPROPERTIES ("skip.header.line.count"="1");

LOAD DATA INPATH '/data/BigData_Student_Performance_Dataset_1000.csv'
OVERWRITE INTO TABLE student_perf_raw;

-- Cast to correct types in cleaned table
CREATE TABLE student_perf AS
SELECT
    student_id,
    name,
    UPPER(TRIM(gender))                        AS gender,
    CAST(age AS INT)                           AS age,
    UPPER(TRIM(department))                    AS department,
    UPPER(TRIM(program))                       AS program,
    CAST(year AS INT)                          AS year,
    CAST(semester AS INT)                      AS semester,
    CAST(attendance AS INT)                    AS attendance,
    CAST(assignment AS INT)                    AS assignment,
    CAST(cat AS INT)                           AS cat,
    CAST(finalexam AS INT)                     AS finalexam,
    CAST(studyhours AS INT)                    AS studyhours,
    UPPER(TRIM(internetaccess))                AS internetaccess,
    UPPER(TRIM(device))                        AS device,
    CAST(parentincome AS INT)                  AS parentincome,
    UPPER(TRIM(scholarship))                   AS scholarship,
    CAST(skillscount AS INT)                   AS skillscount,
    CAST(projects AS INT)                      AS projects,
    CAST(lmslogins AS INT)                     AS lmslogins,
    CAST(libraryvisits AS INT)                 AS libraryvisits,
    INITCAP(TRIM(location))                    AS location,
    UPPER(TRIM(graduated))                     AS graduated,
    UPPER(TRIM(placement))                     AS placement,
    CAST(gpa AS DOUBLE)                        AS gpa,
    CAST(total AS DOUBLE)                      AS total,
    UPPER(TRIM(grade))                         AS grade
FROM student_perf_raw
WHERE student_id IS NOT NULL AND student_id != '';

SELECT CONCAT('Rows loaded into student_perf: ', COUNT(*)) AS load_status FROM student_perf;

-- ============================================================
-- SECTION 1 – DATA QUALITY CHECKS
-- ============================================================
SELECT '=========================================' AS section_header;
SELECT '  SECTION 1: DATA QUALITY CHECKS        ' AS section_header;
SELECT '=========================================' AS section_header;

SELECT '--- 1a. Total Row Count ---' AS label;
SELECT COUNT(*) AS total_rows FROM student_perf;

SELECT '--- 1b. NULL / Missing Values per Column ---' AS label;
SELECT
    SUM(CASE WHEN student_id    IS NULL OR student_id=''    THEN 1 ELSE 0 END) AS null_student_id,
    SUM(CASE WHEN gender        IS NULL OR gender=''        THEN 1 ELSE 0 END) AS null_gender,
    SUM(CASE WHEN age           IS NULL                     THEN 1 ELSE 0 END) AS null_age,
    SUM(CASE WHEN department    IS NULL OR department=''    THEN 1 ELSE 0 END) AS null_department,
    SUM(CASE WHEN program       IS NULL OR program=''       THEN 1 ELSE 0 END) AS null_program,
    SUM(CASE WHEN attendance    IS NULL                     THEN 1 ELSE 0 END) AS null_attendance,
    SUM(CASE WHEN gpa           IS NULL                     THEN 1 ELSE 0 END) AS null_gpa,
    SUM(CASE WHEN grade         IS NULL OR grade=''         THEN 1 ELSE 0 END) AS null_grade,
    SUM(CASE WHEN placement     IS NULL OR placement=''     THEN 1 ELSE 0 END) AS null_placement
FROM student_perf;

SELECT '--- 1c. Duplicate Student IDs ---' AS label;
SELECT COUNT(*) AS duplicate_count
FROM (
    SELECT student_id, COUNT(*) AS cnt
    FROM student_perf
    GROUP BY student_id
    HAVING cnt > 1
) dup;

SELECT '--- 1d. Out-of-Range Attendance (should be 0-100) ---' AS label;
SELECT COUNT(*) AS bad_attendance_rows
FROM student_perf
WHERE attendance < 0 OR attendance > 100;

SELECT '--- 1e. Invalid GPA (should be 0.0-4.0) ---' AS label;
SELECT COUNT(*) AS bad_gpa_rows
FROM student_perf
WHERE gpa < 0.0 OR gpa > 4.0;

SELECT '--- 1f. Distinct Values for Categorical Columns ---' AS label;
SELECT 'Gender values:' AS col_name;
SELECT gender, COUNT(*) AS cnt FROM student_perf GROUP BY gender;
SELECT 'Program values:' AS col_name;
SELECT program, COUNT(*) AS cnt FROM student_perf GROUP BY program;
SELECT 'Grade values:' AS col_name;
SELECT grade, COUNT(*) AS cnt FROM student_perf GROUP BY grade ORDER BY grade;
SELECT 'InternetAccess values:' AS col_name;
SELECT internetaccess, COUNT(*) AS cnt FROM student_perf GROUP BY internetaccess;
SELECT 'Scholarship values:' AS col_name;
SELECT scholarship, COUNT(*) AS cnt FROM student_perf GROUP BY scholarship;
SELECT 'Placement values:' AS col_name;
SELECT placement, COUNT(*) AS cnt FROM student_perf GROUP BY placement;
SELECT 'Graduated values:' AS col_name;
SELECT graduated, COUNT(*) AS cnt FROM student_perf GROUP BY graduated;

-- ============================================================
-- SECTION 2 – OVERALL SUMMARY STATISTICS
-- ============================================================
SELECT '=========================================' AS section_header;
SELECT '  SECTION 2: OVERALL SUMMARY STATISTICS ' AS section_header;
SELECT '=========================================' AS section_header;

SELECT '--- 2a. Numeric Column Statistics ---' AS label;
SELECT
    ROUND(AVG(age),2)           AS avg_age,
    MIN(age)                    AS min_age,
    MAX(age)                    AS max_age,
    ROUND(STDDEV(age),2)        AS std_age,
    ROUND(AVG(gpa),3)           AS avg_gpa,
    MIN(gpa)                    AS min_gpa,
    MAX(gpa)                    AS max_gpa,
    ROUND(STDDEV(gpa),3)        AS std_gpa,
    ROUND(AVG(attendance),2)    AS avg_attendance,
    ROUND(STDDEV(attendance),2) AS std_attendance,
    ROUND(AVG(studyhours),2)    AS avg_studyhours,
    ROUND(AVG(parentincome),0)  AS avg_parentincome,
    MIN(parentincome)           AS min_parentincome,
    MAX(parentincome)           AS max_parentincome,
    ROUND(AVG(lmslogins),2)     AS avg_lmslogins,
    ROUND(AVG(libraryvisits),2) AS avg_libraryvisits,
    ROUND(AVG(skillscount),2)   AS avg_skillscount,
    ROUND(AVG(projects),2)      AS avg_projects
FROM student_perf;

SELECT '--- 2b. Overall Graduation Rate ---' AS label;
SELECT
    COUNT(*) AS total_students,
    SUM(CASE WHEN graduated='YES' THEN 1 ELSE 0 END) AS graduated_count,
    ROUND(100.0 * SUM(CASE WHEN graduated='YES' THEN 1 ELSE 0 END) / COUNT(*), 2) AS graduation_rate_pct
FROM student_perf;

SELECT '--- 2c. Overall Placement Rate ---' AS label;
SELECT
    SUM(CASE WHEN placement='YES' THEN 1 ELSE 0 END) AS placed_count,
    ROUND(100.0 * SUM(CASE WHEN placement='YES' THEN 1 ELSE 0 END) / COUNT(*), 2) AS placement_rate_pct
FROM student_perf;

SELECT '--- 2d. GPA Percentile Approximations ---' AS label;
SELECT
    ROUND(PERCENTILE_APPROX(gpa, 0.25), 3) AS gpa_p25,
    ROUND(PERCENTILE_APPROX(gpa, 0.50), 3) AS gpa_median,
    ROUND(PERCENTILE_APPROX(gpa, 0.75), 3) AS gpa_p75,
    ROUND(PERCENTILE_APPROX(gpa, 0.90), 3) AS gpa_p90
FROM student_perf;

-- ============================================================
-- SECTION 3 – GRADE DISTRIBUTION
-- ============================================================
SELECT '=========================================' AS section_header;
SELECT '  SECTION 3: GRADE DISTRIBUTION         ' AS section_header;
SELECT '=========================================' AS section_header;

SELECT '--- 3a. Grade Count and Percentage ---' AS label;
SELECT
    grade,
    COUNT(*)                                                          AS student_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2)               AS percentage,
    ROUND(AVG(gpa), 3)                                                AS avg_gpa,
    ROUND(AVG(attendance), 2)                                         AS avg_attendance,
    ROUND(AVG(studyhours), 2)                                         AS avg_studyhours
FROM student_perf
GROUP BY grade
ORDER BY grade;

SELECT '--- 3b. GPA Bucket Distribution ---' AS label;
SELECT
    CASE
        WHEN gpa >= 3.5 THEN '3.5-4.0 (Distinction)'
        WHEN gpa >= 3.0 THEN '3.0-3.49 (Credit)'
        WHEN gpa >= 2.5 THEN '2.5-2.99 (Pass)'
        WHEN gpa >= 2.0 THEN '2.0-2.49 (Low Pass)'
        ELSE                 'Below 2.0 (Fail)'
    END AS gpa_band,
    COUNT(*) AS student_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct
FROM student_perf
GROUP BY
    CASE
        WHEN gpa >= 3.5 THEN '3.5-4.0 (Distinction)'
        WHEN gpa >= 3.0 THEN '3.0-3.49 (Credit)'
        WHEN gpa >= 2.5 THEN '2.5-2.99 (Pass)'
        WHEN gpa >= 2.0 THEN '2.0-2.49 (Low Pass)'
        ELSE                 'Below 2.0 (Fail)'
    END
ORDER BY MIN(gpa) DESC;

-- ============================================================
-- SECTION 4 – DEPARTMENT ANALYSIS
-- ============================================================
SELECT '=========================================' AS section_header;
SELECT '  SECTION 4: DEPARTMENT ANALYSIS        ' AS section_header;
SELECT '=========================================' AS section_header;

SELECT '--- 4a. Students per Department ---' AS label;
SELECT
    department,
    COUNT(*)                   AS total_students,
    ROUND(AVG(gpa), 3)         AS avg_gpa,
    ROUND(AVG(attendance), 2)  AS avg_attendance,
    ROUND(AVG(studyhours), 2)  AS avg_studyhours,
    ROUND(AVG(parentincome),0) AS avg_parent_income,
    SUM(CASE WHEN placement='YES' THEN 1 ELSE 0 END)                                             AS placed,
    ROUND(100.0 * SUM(CASE WHEN placement='YES' THEN 1 ELSE 0 END) / COUNT(*), 2)                AS placement_pct,
    SUM(CASE WHEN scholarship='YES' THEN 1 ELSE 0 END)                                            AS scholars,
    ROUND(100.0 * SUM(CASE WHEN scholarship='YES' THEN 1 ELSE 0 END) / COUNT(*), 2)              AS scholarship_pct
FROM student_perf
GROUP BY department
ORDER BY avg_gpa DESC;

SELECT '--- 4b. Grade Distribution per Department ---' AS label;
SELECT
    department,
    SUM(CASE WHEN grade='A' THEN 1 ELSE 0 END) AS grade_A,
    SUM(CASE WHEN grade='B' THEN 1 ELSE 0 END) AS grade_B,
    SUM(CASE WHEN grade='C' THEN 1 ELSE 0 END) AS grade_C,
    SUM(CASE WHEN grade='D' THEN 1 ELSE 0 END) AS grade_D,
    SUM(CASE WHEN grade='F' THEN 1 ELSE 0 END) AS grade_F,
    COUNT(*) AS total
FROM student_perf
GROUP BY department
ORDER BY department;

-- ============================================================
-- SECTION 5 – GENDER ANALYSIS
-- ============================================================
SELECT '=========================================' AS section_header;
SELECT '  SECTION 5: GENDER ANALYSIS            ' AS section_header;
SELECT '=========================================' AS section_header;

SELECT '--- 5a. Performance Metrics by Gender ---' AS label;
SELECT
    gender,
    COUNT(*) AS count,
    ROUND(AVG(gpa), 3)         AS avg_gpa,
    ROUND(AVG(attendance), 2)  AS avg_attendance,
    ROUND(AVG(studyhours), 2)  AS avg_studyhours,
    ROUND(AVG(lmslogins), 2)   AS avg_lmslogins,
    ROUND(100.0 * SUM(CASE WHEN placement='YES' THEN 1 ELSE 0 END) / COUNT(*), 2)   AS placement_pct,
    ROUND(100.0 * SUM(CASE WHEN scholarship='YES' THEN 1 ELSE 0 END) / COUNT(*), 2) AS scholarship_pct,
    ROUND(100.0 * SUM(CASE WHEN graduated='YES' THEN 1 ELSE 0 END) / COUNT(*), 2)   AS graduation_pct
FROM student_perf
GROUP BY gender
ORDER BY avg_gpa DESC;

SELECT '--- 5b. Grade Distribution by Gender ---' AS label;
SELECT
    gender,
    SUM(CASE WHEN grade='A' THEN 1 ELSE 0 END) AS grade_A,
    SUM(CASE WHEN grade='B' THEN 1 ELSE 0 END) AS grade_B,
    SUM(CASE WHEN grade='C' THEN 1 ELSE 0 END) AS grade_C,
    SUM(CASE WHEN grade='D' THEN 1 ELSE 0 END) AS grade_D,
    SUM(CASE WHEN grade='F' THEN 1 ELSE 0 END) AS grade_F
FROM student_perf
GROUP BY gender;

-- ============================================================
-- SECTION 6 – PROGRAM ANALYSIS (BSc vs MSc)
-- ============================================================
SELECT '=========================================' AS section_header;
SELECT '  SECTION 6: PROGRAM ANALYSIS (BSc/MSc) ' AS section_header;
SELECT '=========================================' AS section_header;

SELECT '--- 6a. Key Metrics by Program ---' AS label;
SELECT
    program,
    COUNT(*) AS total,
    ROUND(AVG(gpa), 3)         AS avg_gpa,
    ROUND(AVG(age), 1)         AS avg_age,
    ROUND(AVG(attendance), 2)  AS avg_attendance,
    ROUND(AVG(studyhours), 2)  AS avg_studyhours,
    ROUND(AVG(parentincome),0) AS avg_parent_income,
    ROUND(100.0 * SUM(CASE WHEN placement='YES' THEN 1 ELSE 0 END) / COUNT(*), 2)  AS placement_pct,
    ROUND(100.0 * SUM(CASE WHEN graduated='YES' THEN 1 ELSE 0 END) / COUNT(*), 2)  AS graduation_pct,
    ROUND(100.0 * SUM(CASE WHEN scholarship='YES' THEN 1 ELSE 0 END) / COUNT(*), 2) AS scholarship_pct
FROM student_perf
GROUP BY program;

SELECT '--- 6b. Program x Department Breakdown ---' AS label;
SELECT
    program,
    department,
    COUNT(*) AS students,
    ROUND(AVG(gpa), 3) AS avg_gpa
FROM student_perf
GROUP BY program, department
ORDER BY program, avg_gpa DESC;

-- ============================================================
-- SECTION 7 – ACADEMIC PERFORMANCE BREAKDOWN
-- ============================================================
SELECT '=========================================' AS section_header;
SELECT '  SECTION 7: ACADEMIC PERFORMANCE       ' AS section_header;
SELECT '=========================================' AS section_header;

SELECT '--- 7a. Score Averages by Grade ---' AS label;
SELECT
    grade,
    ROUND(AVG(attendance), 2)  AS avg_attendance,
    ROUND(AVG(assignment), 2)  AS avg_assignment,
    ROUND(AVG(cat), 2)         AS avg_cat,
    ROUND(AVG(finalexam), 2)   AS avg_finalexam,
    ROUND(AVG(total), 2)       AS avg_total,
    COUNT(*) AS students
FROM student_perf
GROUP BY grade
ORDER BY avg_total DESC;

SELECT '--- 7b. Attendance Bands vs GPA ---' AS label;
SELECT
    CASE
        WHEN attendance >= 90 THEN '90-100% (Excellent)'
        WHEN attendance >= 75 THEN '75-89% (Good)'
        WHEN attendance >= 60 THEN '60-74% (Average)'
        ELSE                       'Below 60% (Poor)'
    END AS attendance_band,
    COUNT(*) AS students,
    ROUND(AVG(gpa), 3) AS avg_gpa,
    ROUND(AVG(finalexam), 2) AS avg_finalexam,
    ROUND(100.0 * SUM(CASE WHEN placement='YES' THEN 1 ELSE 0 END) / COUNT(*), 2) AS placement_pct
FROM student_perf
GROUP BY
    CASE
        WHEN attendance >= 90 THEN '90-100% (Excellent)'
        WHEN attendance >= 75 THEN '75-89% (Good)'
        WHEN attendance >= 60 THEN '60-74% (Average)'
        ELSE                       'Below 60% (Poor)'
    END
ORDER BY avg_gpa DESC;

SELECT '--- 7c. Study Hours vs GPA ---' AS label;
SELECT
    CASE
        WHEN studyhours >= 8  THEN '8+ hrs/day (High)'
        WHEN studyhours >= 5  THEN '5-7 hrs/day (Medium)'
        WHEN studyhours >= 2  THEN '2-4 hrs/day (Low)'
        ELSE                       '0-1 hr/day (Very Low)'
    END AS study_band,
    COUNT(*) AS students,
    ROUND(AVG(gpa), 3) AS avg_gpa,
    ROUND(AVG(attendance), 2) AS avg_attendance
FROM student_perf
GROUP BY
    CASE
        WHEN studyhours >= 8  THEN '8+ hrs/day (High)'
        WHEN studyhours >= 5  THEN '5-7 hrs/day (Medium)'
        WHEN studyhours >= 2  THEN '2-4 hrs/day (Low)'
        ELSE                       '0-1 hr/day (Very Low)'
    END
ORDER BY avg_gpa DESC;

-- ============================================================
-- SECTION 8 – ENGAGEMENT METRICS
-- ============================================================
SELECT '=========================================' AS section_header;
SELECT '  SECTION 8: ENGAGEMENT METRICS         ' AS section_header;
SELECT '=========================================' AS section_header;

SELECT '--- 8a. LMS Login Bands vs GPA ---' AS label;
SELECT
    CASE
        WHEN lmslogins >= 150 THEN '150+ (Very Active)'
        WHEN lmslogins >= 100 THEN '100-149 (Active)'
        WHEN lmslogins >= 50  THEN '50-99 (Moderate)'
        ELSE                       '0-49 (Inactive)'
    END AS lms_band,
    COUNT(*) AS students,
    ROUND(AVG(gpa), 3) AS avg_gpa,
    ROUND(AVG(finalexam), 2) AS avg_finalexam
FROM student_perf
GROUP BY
    CASE
        WHEN lmslogins >= 150 THEN '150+ (Very Active)'
        WHEN lmslogins >= 100 THEN '100-149 (Active)'
        WHEN lmslogins >= 50  THEN '50-99 (Moderate)'
        ELSE                       '0-49 (Inactive)'
    END
ORDER BY avg_gpa DESC;

SELECT '--- 8b. Library Visits vs GPA ---' AS label;
SELECT
    CASE
        WHEN libraryvisits >= 40 THEN '40+ visits (Very High)'
        WHEN libraryvisits >= 25 THEN '25-39 visits (High)'
        WHEN libraryvisits >= 10 THEN '10-24 visits (Medium)'
        ELSE                          '0-9 visits (Low)'
    END AS library_band,
    COUNT(*) AS students,
    ROUND(AVG(gpa), 3) AS avg_gpa
FROM student_perf
GROUP BY
    CASE
        WHEN libraryvisits >= 40 THEN '40+ visits (Very High)'
        WHEN libraryvisits >= 25 THEN '25-39 visits (High)'
        WHEN libraryvisits >= 10 THEN '10-24 visits (Medium)'
        ELSE                          '0-9 visits (Low)'
    END
ORDER BY avg_gpa DESC;

SELECT '--- 8c. Skills Count vs GPA ---' AS label;
SELECT
    skillscount,
    COUNT(*) AS students,
    ROUND(AVG(gpa), 3) AS avg_gpa,
    ROUND(100.0 * SUM(CASE WHEN placement='YES' THEN 1 ELSE 0 END) / COUNT(*), 2) AS placement_pct
FROM student_perf
GROUP BY skillscount
ORDER BY skillscount;

SELECT '--- 8d. Projects vs Placement ---' AS label;
SELECT
    projects,
    COUNT(*) AS students,
    ROUND(AVG(gpa), 3) AS avg_gpa,
    ROUND(100.0 * SUM(CASE WHEN placement='YES' THEN 1 ELSE 0 END) / COUNT(*), 2) AS placement_pct
FROM student_perf
GROUP BY projects
ORDER BY projects;

-- ============================================================
-- SECTION 9 – SOCIOECONOMIC ANALYSIS
-- ============================================================
SELECT '=========================================' AS section_header;
SELECT '  SECTION 9: SOCIOECONOMIC ANALYSIS     ' AS section_header;
SELECT '=========================================' AS section_header;

SELECT '--- 9a. Parent Income Quintile vs GPA & Placement ---' AS label;
SELECT
    CASE
        WHEN parentincome >= 240000 THEN 'Q5: Top 20% (240k+)'
        WHEN parentincome >= 180000 THEN 'Q4: Upper Mid (180k-240k)'
        WHEN parentincome >= 120000 THEN 'Q3: Middle (120k-180k)'
        WHEN parentincome >= 60000  THEN 'Q2: Lower Mid (60k-120k)'
        ELSE                             'Q1: Bottom 20% (<60k)'
    END AS income_quintile,
    COUNT(*) AS students,
    ROUND(AVG(gpa), 3) AS avg_gpa,
    ROUND(AVG(attendance), 2) AS avg_attendance,
    ROUND(100.0 * SUM(CASE WHEN placement='YES' THEN 1 ELSE 0 END) / COUNT(*), 2) AS placement_pct,
    ROUND(100.0 * SUM(CASE WHEN scholarship='YES' THEN 1 ELSE 0 END) / COUNT(*), 2) AS scholarship_pct
FROM student_perf
GROUP BY
    CASE
        WHEN parentincome >= 240000 THEN 'Q5: Top 20% (240k+)'
        WHEN parentincome >= 180000 THEN 'Q4: Upper Mid (180k-240k)'
        WHEN parentincome >= 120000 THEN 'Q3: Middle (120k-180k)'
        WHEN parentincome >= 60000  THEN 'Q2: Lower Mid (60k-120k)'
        ELSE                             'Q1: Bottom 20% (<60k)'
    END
ORDER BY MIN(parentincome) DESC;

-- ============================================================
-- SECTION 10 – TECHNOLOGY ACCESS
-- ============================================================
SELECT '=========================================' AS section_header;
SELECT '  SECTION 10: TECHNOLOGY ACCESS         ' AS section_header;
SELECT '=========================================' AS section_header;

SELECT '--- 10a. Internet Access vs GPA & Placement ---' AS label;
SELECT
    internetaccess,
    COUNT(*) AS students,
    ROUND(AVG(gpa), 3) AS avg_gpa,
    ROUND(AVG(lmslogins), 2) AS avg_lmslogins,
    ROUND(100.0 * SUM(CASE WHEN placement='YES' THEN 1 ELSE 0 END) / COUNT(*), 2) AS placement_pct
FROM student_perf
GROUP BY internetaccess;

SELECT '--- 10b. Device Type vs GPA & Placement ---' AS label;
SELECT
    device,
    COUNT(*) AS students,
    ROUND(AVG(gpa), 3) AS avg_gpa,
    ROUND(AVG(lmslogins), 2) AS avg_lmslogins,
    ROUND(100.0 * SUM(CASE WHEN placement='YES' THEN 1 ELSE 0 END) / COUNT(*), 2) AS placement_pct
FROM student_perf
GROUP BY device
ORDER BY avg_gpa DESC;

SELECT '--- 10c. Internet x Device Cross Table ---' AS label;
SELECT
    internetaccess,
    device,
    COUNT(*) AS students,
    ROUND(AVG(gpa), 3) AS avg_gpa
FROM student_perf
GROUP BY internetaccess, device
ORDER BY avg_gpa DESC;

-- ============================================================
-- SECTION 11 – TOP & BOTTOM PERFORMERS
-- ============================================================
SELECT '=========================================' AS section_header;
SELECT '  SECTION 11: TOP & BOTTOM PERFORMERS   ' AS section_header;
SELECT '=========================================' AS section_header;

SELECT '--- 11a. Top 10 Students by GPA ---' AS label;
SELECT
    student_id, name, department, program, gpa, grade,
    attendance, studyhours, placement
FROM student_perf
ORDER BY gpa DESC
LIMIT 10;

SELECT '--- 11b. Bottom 10 Students by GPA ---' AS label;
SELECT
    student_id, name, department, program, gpa, grade,
    attendance, studyhours, placement
FROM student_perf
ORDER BY gpa ASC
LIMIT 10;

SELECT '--- 11c. Students Below 60% Attendance ---' AS label;
SELECT
    COUNT(*) AS low_attendance_students,
    ROUND(AVG(gpa), 3) AS avg_gpa,
    ROUND(AVG(finalexam), 2) AS avg_finalexam
FROM student_perf
WHERE attendance < 60;

SELECT '--- 11d. High Performers Without Placement ---' AS label;
SELECT
    student_id, name, department, gpa, skillscount, projects, location
FROM student_perf
WHERE gpa >= 3.5 AND placement = 'NO'
ORDER BY gpa DESC
LIMIT 15;

-- ============================================================
-- SECTION 12 – LOCATION ANALYSIS
-- ============================================================
SELECT '=========================================' AS section_header;
SELECT '  SECTION 12: LOCATION ANALYSIS         ' AS section_header;
SELECT '=========================================' AS section_header;

SELECT '--- 12a. Students per City ---' AS label;
SELECT
    location,
    COUNT(*) AS students,
    ROUND(AVG(gpa), 3) AS avg_gpa,
    ROUND(AVG(parentincome), 0) AS avg_parent_income,
    ROUND(100.0 * SUM(CASE WHEN placement='YES' THEN 1 ELSE 0 END) / COUNT(*), 2) AS placement_pct,
    ROUND(100.0 * SUM(CASE WHEN internetaccess='YES' THEN 1 ELSE 0 END) / COUNT(*), 2) AS internet_access_pct
FROM student_perf
GROUP BY location
ORDER BY placement_pct DESC;

-- ============================================================
-- SECTION 13 – SCHOLARSHIP IMPACT
-- ============================================================
SELECT '=========================================' AS section_header;
SELECT '  SECTION 13: SCHOLARSHIP IMPACT        ' AS section_header;
SELECT '=========================================' AS section_header;

SELECT '--- 13a. Scholarship vs No Scholarship ---' AS label;
SELECT
    scholarship,
    COUNT(*) AS students,
    ROUND(AVG(gpa), 3) AS avg_gpa,
    ROUND(AVG(attendance), 2) AS avg_attendance,
    ROUND(AVG(studyhours), 2) AS avg_studyhours,
    ROUND(AVG(parentincome), 0) AS avg_parent_income,
    ROUND(100.0 * SUM(CASE WHEN placement='YES' THEN 1 ELSE 0 END) / COUNT(*), 2) AS placement_pct,
    ROUND(100.0 * SUM(CASE WHEN graduated='YES' THEN 1 ELSE 0 END) / COUNT(*), 2) AS graduation_pct
FROM student_perf
GROUP BY scholarship;

SELECT '--- 13b. Scholarship by Department ---' AS label;
SELECT
    department,
    SUM(CASE WHEN scholarship='YES' THEN 1 ELSE 0 END) AS scholars,
    COUNT(*) AS total,
    ROUND(100.0 * SUM(CASE WHEN scholarship='YES' THEN 1 ELSE 0 END) / COUNT(*), 2) AS scholarship_rate
FROM student_perf
GROUP BY department
ORDER BY scholarship_rate DESC;

-- ============================================================
-- SECTION 14 – WINDOW FUNCTIONS: RANKING WITHIN DEPARTMENT
-- ============================================================
SELECT '=========================================' AS section_header;
SELECT '  SECTION 14: RANKINGS (WINDOW FUNCS)   ' AS section_header;
SELECT '=========================================' AS section_header;

SELECT '--- 14a. Top 3 Students per Department by GPA ---' AS label;
SELECT *
FROM (
    SELECT
        student_id, name, department, program, gpa, grade, placement,
        RANK() OVER (PARTITION BY department ORDER BY gpa DESC) AS dept_rank
    FROM student_perf
) ranked
WHERE dept_rank <= 3
ORDER BY department, dept_rank;

SELECT '--- 14b. GPA Percentile Rank per Department ---' AS label;
SELECT
    student_id, name, department, gpa,
    ROUND(PERCENT_RANK() OVER (PARTITION BY department ORDER BY gpa) * 100, 1) AS percentile_in_dept,
    ROUND(PERCENT_RANK() OVER (ORDER BY gpa) * 100, 1) AS overall_percentile
FROM student_perf
ORDER BY department, percentile_in_dept DESC
LIMIT 30;

SELECT '--- 14c. Running Average GPA by Department (sorted by GPA desc) ---' AS label;
SELECT
    department,
    student_id,
    gpa,
    ROUND(AVG(gpa) OVER (PARTITION BY department ORDER BY gpa DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 3) AS running_avg_gpa
FROM student_perf
ORDER BY department, gpa DESC
LIMIT 30;

-- ============================================================
-- FINAL SUMMARY
-- ============================================================
SELECT '=========================================' AS section_header;
SELECT '  DESCRIPTIVE ANALYSIS COMPLETE!        ' AS section_header;
SELECT '=========================================' AS section_header;

SELECT
    COUNT(*) AS total_students,
    ROUND(AVG(gpa), 3) AS overall_avg_gpa,
    ROUND(100.0 * SUM(CASE WHEN placement='YES' THEN 1 ELSE 0 END) / COUNT(*), 2) AS overall_placement_pct,
    ROUND(100.0 * SUM(CASE WHEN graduated='YES' THEN 1 ELSE 0 END) / COUNT(*), 2) AS overall_graduation_pct,
    ROUND(100.0 * SUM(CASE WHEN scholarship='YES' THEN 1 ELSE 0 END) / COUNT(*), 2) AS scholarship_rate_pct
FROM student_perf;
