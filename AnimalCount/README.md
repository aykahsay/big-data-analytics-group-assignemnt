# Distributed Animal Census using Hadoop & IntelliJ IDEA

This folder contains a MapReduce application that counts the frequency of animal sightings from a raw text log file. It was developed using Java, Maven, and Apache Hadoop.

## Prerequisites
- Java JDK 8 or 11
- Apache Hadoop (Single-node or cluster)
- Maven

## How to Run

### 1. Start Hadoop Daemons
Ensure that your Hadoop HDFS and YARN daemons are running:
```bash
start-dfs.sh
start-yarn.sh
jps # Verify NameNode, DataNode, ResourceManager, and NodeManager are running
```

### 2. Upload Data to HDFS
First, create an input directory in HDFS and upload the dataset:
```bash
hdfs dfs -mkdir -p /user/student/animal_census/input
hdfs dfs -put animals.txt /user/student/animal_census/input/
```

### 3. Build the Project
Use Maven to compile the Java code and package it into a JAR file. You can run this inside the `AnimalCount` directory:
```bash
mvn clean package
```
This will generate a JAR file (e.g., `HadoopAnimalCount-1.0-SNAPSHOT.jar`) in the `target/` directory.

### 4. Execute the MapReduce Job
Run the MapReduce job using the Hadoop `jar` command. 
*Note: Make sure the output directory does not already exist in HDFS.*
```bash
hadoop jar target/HadoopAnimalCount-1.0-SNAPSHOT.jar AnimalCount /user/student/animal_census/input /user/student/animal_census/output
```

### 5. View the Results
Once the job completes successfully, you can view the aggregated animal counts:
```bash
hdfs dfs -cat /user/student/animal_census/output/part-r-00000
```
