-- Databricks notebook source
-- MAGIC 
-- MAGIC %md-sandbox
-- MAGIC 
-- MAGIC <div style="text-align: center; line-height: 0; padding-top: 9px;">
-- MAGIC   <img src="https://databricks.com/wp-content/uploads/2018/03/db-academy-rgb-1200px.png" alt="Databricks Learning" style="width: 600px">
-- MAGIC </div>

-- COMMAND ----------

-- MAGIC %md
-- MAGIC # Lab 2 - Data Munging
-- MAGIC ## Module 5 Assignment
-- MAGIC 
-- MAGIC In this exercise, you will be working with mock data meant to replicate data from an ecommerce mattress seller. Broadly, your work is to clean up and present this data so that it can be used to target geographic areas.  Work through the tasks below and answer the challenge to produce the required report. 
-- MAGIC 
-- MAGIC ## ![Spark Logo Tiny](https://files.training.databricks.com/images/105/logo_spark_tiny.png) In this assignment you will: </br>
-- MAGIC 
-- MAGIC * Work with hierarchical data
-- MAGIC * Use common table expressions to display data
-- MAGIC * Create new tables based on existing tables
-- MAGIC * Manage working with null values and timestamps
-- MAGIC 
-- MAGIC As you work through the following tasks, you will be prompted to enter selected answers in Coursera. Find the quiz associated with this lab to enter your answers. 
-- MAGIC 
-- MAGIC Run the cell below to prepare this workspace for the lab. 

-- COMMAND ----------

-- MAGIC %run ../Includes/Classroom-Setup

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Exercise 1: Create a table
-- MAGIC **Summary:** Create a new table named `eventsRaw` 
-- MAGIC 
-- MAGIC Use this path to access the data: `/mnt/training/ecommerce/events/events.parquet`
-- MAGIC 
-- MAGIC Steps to complete: 
-- MAGIC * Make sure this notebook is idempotent by first dropping the table named `eventsRaw`, if it exists already
-- MAGIC * Use the provided path to read in the data

-- COMMAND ----------

--TODO
DROP TABLE IF EXISTS eventsRaw;
CREATE TABLE eventsRaw
USING parquet                           
OPTIONS (
    PATH "/mnt/training/ecommerce/events/events.parquet"
    )

-- COMMAND ----------

SELECT * FROM eventsRaw

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Exercise 2: Understand the schema and metadata
-- MAGIC 
-- MAGIC **Summary:** Run a command to display this table's schema and other detailed table information
-- MAGIC 
-- MAGIC Notice that this table includes `ArrayType` and `StructType` data
-- MAGIC 
-- MAGIC Steps to complete: 
-- MAGIC * Run a single command to display the table information
-- MAGIC * **Answer the corresponding question in Coursera, in the quiz for this module, regarding the location of this table**

-- COMMAND ----------

--TODO
DESCRIBE EXTENDED eventsRaw;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Exercise 3: Sample the table
-- MAGIC 
-- MAGIC **Summary:** Sample this table to get a closer look at the data
-- MAGIC 
-- MAGIC Steps to complete: 
-- MAGIC * Sample the table to display up to 1 percent of the records

-- COMMAND ----------

--TODO
SELECT * FROM eventsRaw TABLESAMPLE (1 PERCENT) ORDER BY device 

-- COMMAND ----------

SELECT ecommerce,geo,items
FROM eventsRaw;

-- COMMAND ----------

-- MAGIC %md-sandbox
-- MAGIC ## Exercise 4: Create a new table
-- MAGIC 
-- MAGIC **Summary:** Create a table `purchaseEvents` that includes event data _with_ purchases that has the following schema: 
-- MAGIC 
-- MAGIC | ColumnName      | DataType| 
-- MAGIC |-----------------|---------|
-- MAGIC |purchases        |double   |
-- MAGIC |previousEventDate|date     |
-- MAGIC |eventDate        |date     |
-- MAGIC |city             |string   |
-- MAGIC |state            |string   |
-- MAGIC |userId           |string   |
-- MAGIC 
-- MAGIC 
-- MAGIC <img alt="Caution" title="Caution" style="vertical-align: text-bottom; position: relative; height:1.3em; top:0.0em" src="https://files.training.databricks.com/static/images/icon-warning.svg"/> The timestamps in this table are meant to match those used in Google Analytics, which measures time to the microsecond. To convert to unixtime, you must divide these values by 1000000 (10e6) before casting to a timestamp. 
-- MAGIC 
-- MAGIC <img alt="Hint" title="Hint" style="vertical-align: text-bottom; position: relative; height:1.75em; top:0.3em" src="https://files.training.databricks.com/static/images/icon-light-bulb.svg"/>&nbsp;**Hint:** Access values from StructType objects using dot notation
-- MAGIC 
-- MAGIC Steps to complete: 
-- MAGIC * Make sure this notebook is idempotent by first dropping the table, if it exists
-- MAGIC * Create a table based on the existing table
-- MAGIC * Use a common table expression to manipulate your data before writing the `SELECT` statement that will define your table _(Recommended)_
-- MAGIC * Do not include records where the `purchase_revenue_in_usd` is `NULL`
-- MAGIC * Sort the table so that the city and state with the greatest total purchase is listed first 

-- COMMAND ----------

SELECT count(*) FROM eventsRaw WHERE ecommerce.purchase_revenue_in_usd  IS NULL;

-- COMMAND ----------

CREATE
OR REPLACE TEMPORARY VIEW eventsRawView AS
SELECT 
  ecommerce,
  timestamp(event_previous_timestamp/1000000) as event_previous_date,
  timestamp(event_timestamp/1000000) as event_date,
  geo,
  user_id
FROM eventsRaw
WHERE ecommerce.purchase_revenue_in_usd IS NOT NULL


-- COMMAND ----------

SELECT * FROM eventsRawView

-- COMMAND ----------

--TODO
DROP TABLE IF EXISTS purchaseEvents;
CREATE TABLE purchaseEvents                 
USING parquet
WITH purchaseView                       -- The start of the CTE from the last cell
AS
  (
  SELECT 
  ecommerce,
  event_previous_date,
  event_date,
  geo,
  user_id
  FROM eventsRawView
  )
SELECT 
  ecommerce.purchase_revenue_in_usd purchases,
  event_previous_date previousEventDate,                       
  event_date eventDate,
  geo.city city,
  geo.state state,
  user_id userId
  
FROM purchaseView;

-- COMMAND ----------



-- COMMAND ----------

SELECT * FROM purchaseEvents

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Exercise 5: Count the records
-- MAGIC 
-- MAGIC **Summary:** Count all the records in your new table. 
-- MAGIC 
-- MAGIC Steps to complete:
-- MAGIC * Write a `SELECT` statement that counts the records in `purchaseEvents`
-- MAGIC * **Answer the corresponding quiz question in Coursera**

-- COMMAND ----------

SELECT count(*) from purchaseEvents

-- COMMAND ----------

--TODO
SELECT count(*) from purchaseEvents


-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Exercise 6: Find the location with the top purchase
-- MAGIC **Summary:** Write a query to produce the city and state where the top purchase amount originated. 
-- MAGIC 
-- MAGIC Steps to complete: 
-- MAGIC * Write a query, sorted by `purchases`, that shows the city and state of the top purchase
-- MAGIC * **Answer the corresponding quiz question in Coursera**

-- COMMAND ----------

--TODO
SELECT * FROM purchaseEvents

-- COMMAND ----------

SELECT
 SUM(purchases) totalPurchases,
 state,
 city
FROM
  purchaseEvents
GROUP BY
  state,city
ORDER BY 
  totalPurchases DESC

-- COMMAND ----------

-- MAGIC %md-sandbox
-- MAGIC ## Challenge: Produce reports
-- MAGIC 
-- MAGIC **Summary:** Use the `purchaseEvents` table to produce queries that explore purchase patterns in the table. Add visualizations to a dashboard to produce one comprehensive customer report.  
-- MAGIC 
-- MAGIC Steps to complete: 
-- MAGIC * Create visualizations to report on: 
-- MAGIC   * total purchases by day of week
-- MAGIC   * average purchases by date of purchase
-- MAGIC   * total purchases by state
-- MAGIC   * Any other patterns you can find in the data
-- MAGIC * Join your table with the data at the path listed below to get list of customers with confirmed email addresses
-- MAGIC * **Answer the corresponding quiz question in Coursera**
-- MAGIC 
-- MAGIC <img alt="Side Note" title="Side Note" style="vertical-align: text-bottom; position: relative; height:1.75em; top:0.05em; transform:rotate(15deg)" src="https://files.training.databricks.com/static/images/icon-note.webp"/> Access the data that holds user email addresses. You can read the data from this path: `/mnt/training/ecommerce/users/users.parquet`

-- COMMAND ----------

--TODO

-- COMMAND ----------

--TODO

-- COMMAND ----------

--TODO

-- COMMAND ----------

--TODO

-- COMMAND ----------

--TODO

-- COMMAND ----------

-- MAGIC %run ../Includes/Classroom-Cleanup

-- COMMAND ----------

-- MAGIC %md-sandbox
-- MAGIC &copy; 2020 Databricks, Inc. All rights reserved.<br/>
-- MAGIC Apache, Apache Spark, Spark and the Spark logo are trademarks of the <a href="http://www.apache.org/">Apache Software Foundation</a>.<br/>
-- MAGIC <br/>
-- MAGIC <a href="https://databricks.com/privacy-policy">Privacy Policy</a> | <a href="https://databricks.com/terms-of-use">Terms of Use</a> | <a href="http://help.databricks.com/">Support</a>
