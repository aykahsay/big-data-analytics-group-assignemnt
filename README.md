# Big Data Analytics - Student Performance

This project demonstrates a Descriptive and Predictive analysis pipeline of student performance data using Hadoop and Apache Hive. 

## 🐳 Docker Setup
This project has been fully containerized so you don't need to manually install Hadoop or configure a PostgreSQL metastore on your host machine.

### Prerequisites
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed on Windows (or Docker Engine on Linux).

### Running the Cluster
1. Open a terminal in this directory.
2. Spin up the cluster:
   ```bash
   docker-compose up -d
   ```
   This will start a Hadoop Namenode, Datanode, PostgreSQL Database (for Hive Metastore), and a HiveServer2 instance.

3. Wait 1-2 minutes for the Metastore to initialize.

4. Run the queries inside the Hive container:
   ```bash
   # Upload data to HDFS
   docker exec -it hive-server bash -c "hdfs dfs -mkdir -p /user/hive/student_data && hdfs dfs -put /data/student_performance.csv /user/hive/student_data/"
   
   # Execute the Hive queries
   docker exec -it hive-server beeline -u jdbc:hive2://localhost:10000 -n hive -f /scripts/student_queries.sql
   ```

5. When you are done, tear down the cluster:
   ```bash
   docker-compose down
   ```

## 📊 Analytics Executed
- **Task 1:** Count Students by Department
- **Task 2:** Average GPA by Department
- **Task 3:** Students with Attendance Below 60%
- **Task 4:** Placement Rate by Program
- **Task 5:** Ranking Students Within Departments

## 📝 Outputs
All raw outputs, LaTeX reports, and PNG visualizations generated from the analysis are included in the `images/` directory and `student_report.tex`.
