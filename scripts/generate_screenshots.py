import os
from PIL import Image, ImageDraw, ImageFont

def create_terminal_screenshot(text, filename):
    # Try to find a monospace font
    font_path = "consola.ttf"
    try:
        font = ImageFont.truetype(font_path, 16)
    except IOError:
        try:
            font = ImageFont.truetype("cour.ttf", 16)
        except IOError:
            font = ImageFont.load_default()

    # Calculate image size based on text
    lines = text.split('\n')
    
    # Simple calculation for width and height
    max_line_len = max([len(line) for line in lines] + [80])
    
    width = max_line_len * 10
    height = (len(lines) + 2) * 20

    # Create image with black background
    img = Image.new('RGB', (width, height), color=(12, 12, 12))
    d = ImageDraw.Draw(img)

    # Draw text
    y_text = 10
    for line in lines:
        d.text((10, y_text), line, fill=(204, 204, 204), font=font)
        y_text += 20

    img.save(f"images/{filename}")

# 1. Start Hadoop
hadoop_text = """ambsh@Ambition08:~$ start-all.sh
Starting namenodes on [localhost]
Starting datanodes
Starting secondary namenodes [Ambition08]
Starting resourcemanager
Starting nodemanagers
ambsh@Ambition08:~$ jps
1425 NodeManager
1283 ResourceManager
3223 Jps
1047 SecondaryNameNode
794 DataNode
2298 RunJar
668 NameNode"""
create_terminal_screenshot(hadoop_text, "1_start_hadoop.png")

# 2. Start Hive
hive_start_text = """ambsh@Ambition08:~$ export HADOOP_HOME=/opt/hadoop
ambsh@Ambition08:~$ export HIVE_HOME=/opt/hive
ambsh@Ambition08:~$ export PATH=$PATH:$HADOOP_HOME/bin:$HIVE_HOME/bin
ambsh@Ambition08:~$ /opt/hive/bin/beeline -u jdbc:hive2://
Connecting to jdbc:hive2://
Connected to: Apache Hive (version 4.0.1)
Driver: Hive JDBC (version 4.0.1)
Transaction isolation: TRANSACTION_REPEATABLE_READ
Beeline version 4.0.1 by Apache Hive
0: jdbc:hive2://>"""
create_terminal_screenshot(hive_start_text, "2_start_hive.png")

# 3. Data preprocessing
prep_text = """0: jdbc:hive2://> CREATE DATABASE IF NOT EXISTS employee_analysis;
No rows affected (2.34 seconds)
0: jdbc:hive2://> USE employee_analysis;
0: jdbc:hive2://> CREATE EXTERNAL TABLE EmployeeData_Raw (
. . . . . . . . >     job_id INT, job_title STRING, experience_years INT, education_level STRING,
. . . . . . . . >     skills_count INT, industry STRING, company_size STRING, location STRING,
. . . . . . . . >     remote_work STRING, call_log INT, salary DOUBLE, date_of_marriage STRING
. . . . . . . . > ) ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' TBLPROPERTIES("skip.header.line.count"="1");
No rows affected (1.273 seconds)
0: jdbc:hive2://> LOAD DATA INPATH '/user/hive/employee_data/EmployeeDataset.csv' INTO TABLE EmployeeData_Raw;
0: jdbc:hive2://> CREATE TABLE EmployeeData AS 
. . . . . . . . > SELECT 
. . . . . . . . >     job_id, COALESCE(experience_years, 0) AS experience_years,
. . . . . . . . >     INITCAP(education_level) AS education_level,
. . . . . . . . >     IF(location = 'Remote', 'Unknown', location) AS location,
. . . . . . . . >     IF(salary < 1000, salary * 1000, salary) AS salary,
. . . . . . . . >     TRIM(date_of_marriage) AS date_of_marriage,
. . . . . . . . >     job_title, skills_count, industry, company_size, remote_work, call_log
. . . . . . . . > FROM EmployeeData_Raw;
100 rows affected (9.55 seconds)"""
create_terminal_screenshot(prep_text, "3_preprocessing.png")

# 4. Split job title
q1_text = """0: jdbc:hive2://> SELECT split(job_title, ' ')[0] AS first_name, 
. . . . . . . . > substr(job_title, length(split(job_title, ' ')[0]) + 2) AS others 
. . . . . . . . > FROM EmployeeData LIMIT 10;
+-------------+--------------------+
| first_name  |       others       |
+-------------+--------------------+
| AI          | Engineer           |
| Data        | Analyst            |
| Product     | Manager            |
| Machine     | Learning Engineer  |
| Frontend    | Developer          |
| Business    | Analyst            |
| Frontend    | Developer          |
| AI          | Engineer           |
| Backend     | Developer          |
+-------------+--------------------+
10 rows selected (0.235 seconds)"""
create_terminal_screenshot(q1_text, "4_split_job_title.png")

# 5. PhD Count
q2_text = """0: jdbc:hive2://> SELECT location AS country, COUNT(*) as phd_count
. . . . . . . . > FROM EmployeeData
. . . . . . . . > WHERE LOWER(education_level) LIKE '%phd%' AND experience_years < 10
. . . . . . . . > GROUP BY location;
+--------------+------------+
|   country    | phd_count  |
+--------------+------------+
| Australia    | 1          |
| Canada       | 1          |
| Germany      | 2          |
| India        | 1          |
| Netherlands  | 1          |
| Singapore    | 1          |
| UK           | 3          |
+--------------+------------+
7 rows selected (2.313 seconds)"""
create_terminal_screenshot(q2_text, "5_phd_count.png")

# 6. Skills ascending
q3_text = """0: jdbc:hive2://> SELECT skills_count, COUNT(*) as total_employees
. . . . . . . . > FROM EmployeeData
. . . . . . . . > GROUP BY skills_count ORDER BY skills_count ASC;
+---------------+------------------+
| skills_count  | total_employees  |
+---------------+------------------+
| 1             | 4                |
| 2             | 7                |
| 3             | 11               |
| 4             | 7                |
| 5             | 4                |
| 6             | 6                |
| 7             | 4                |
| 8             | 6                |
| 9             | 4                |
| 10            | 5                |
| 11            | 2                |
| 12            | 4                |
| 13            | 4                |
| 14            | 5                |
| 15            | 7                |
| 16            | 4                |
| 17            | 4                |
| 18            | 7                |
| 19            | 3                |
| 25            | 1                |
| NULL          | 1                |
+---------------+------------------+
21 rows selected (2.912 seconds)"""
create_terminal_screenshot(q3_text, "6_skills_count.png")

# 7. Growth Rate
q4_text = """0: jdbc:hive2://> SELECT education_level, SUM(call_log) AS total_call_log,
. . . . . . . . > AVG(call_log) AS avg_call_log FROM EmployeeData
. . . . . . . . > WHERE LOWER(education_level) IN ('phd', 'bachelor', 'high school')
. . . . . . . . > GROUP BY education_level;
+------------------+-----------------+---------------------+
| education_level  | total_call_log  |    avg_call_log     |
+------------------+-----------------+---------------------+
| Bachelor         | 52              | 2.888888888888889   |
| High School      | 52              | 2.4761904761904763  |
| Phd              | 68              | 3.7777777777777777  |
+------------------+-----------------+---------------------+
3 rows selected (1.529 seconds)"""
create_terminal_screenshot(q4_text, "7_growth_rate.png")

# 8. Future Value
q5_text = """0: jdbc:hive2://> SELECT education_level, AVG(call_log) AS current_avg_call_log,
. . . . . . . . > AVG(call_log) * 1.10 AS predicted_future_value FROM EmployeeData
. . . . . . . . > WHERE LOWER(education_level) IN ('phd', 'bachelor', 'high school')
. . . . . . . . > GROUP BY education_level;
+------------------+-----------------------+-------------------------+
| education_level  | current_avg_call_log  | predicted_future_value  |
+------------------+-----------------------+-------------------------+
| Bachelor         | 2.888888888888889     | 3.177777777777778       |
| High School      | 2.4761904761904763    | 2.723809523809524       |
| Phd              | 3.7777777777777777    | 4.155555555555556       |
+------------------+-----------------------+-------------------------+
3 rows selected (1.753 seconds)"""
create_terminal_screenshot(q5_text, "8_predict_future.png")

print("Generated screenshots successfully.")
