-- Databricks notebook source
select * from dataengineering.video1.users_dirty_csv

-- COMMAND ----------

SELECT user_id, COUNT(*) as duplicate_count
FROM dataengineering.video1.users_dirty_csv
GROUP BY user_id
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC

-- COMMAND ----------

-- Step 1: Find the maximum user_id number to continue the sequence
WITH max_id AS (
  SELECT CAST(MAX(CAST(SUBSTRING(user_id, 5) AS INT)) AS INT) as max_user_id
  FROM dataengineering.video1.users_datecleaned
),

-- Step 2: Identify duplicates and assign new IDs
deduplicated AS (
  SELECT 
    *,
    ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY signup_date) as row_num
  FROM dataengineering.video1.users_datecleaned
),

-- Step 3: Assign row numbers to duplicates for new ID generation
duplicates_numbered AS (
  SELECT 
    *,
    ROW_NUMBER() OVER (ORDER BY signup_date) as dup_row_num
  FROM deduplicated
  WHERE row_num > 1
)

-- Step 4: Combine first occurrences with reassigned duplicates
SELECT 
  user_id,
  first_name,
  last_name,
  email,
  signup_date,
  country,
  referral_source
FROM deduplicated
WHERE row_num = 1

UNION ALL

SELECT 
  CONCAT('USR_', CAST((SELECT max_user_id FROM max_id) + dup_row_num AS STRING)) as user_id,
  first_name,
  last_name,
  email,
  signup_date,
  country,
  referral_source
FROM duplicates_numbered
ORDER BY signup_date

-- COMMAND ----------



-- COMMAND ----------

CREATE OR REPLACE TABLE dataengineering.video1.users_datecleaned AS
SELECT 
  user_id,
  first_name,
  last_name,
  email,
  TO_DATE(REPLACE(signup_date, '.', '/'), 'M/d/yy') as signup_date,
  country,
  referral_source
FROM dataengineering.video1.users_dirty_csv

-- COMMAND ----------

-- DBTITLE 1,Siver Table Data 1
select * from dataengineering.video1.users_datecleaned

-- COMMAND ----------

CREATE OR REPLACE TABLE dataengineering.video1.users_date_uidcleaned AS
WITH max_id AS (
  SELECT CAST(MAX(CAST(SUBSTRING(user_id, 5) AS INT)) AS INT) as max_user_id
  FROM dataengineering.video1.users_datecleaned
),

deduplicated AS (
  SELECT 
    *,
    ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY signup_date) as row_num
  FROM dataengineering.video1.users_datecleaned
),

duplicates_numbered AS (
  SELECT 
    *,
    ROW_NUMBER() OVER (ORDER BY signup_date) as dup_row_num
  FROM deduplicated
  WHERE row_num > 1
)

SELECT 
  user_id,
  first_name,
  last_name,
  email,
  signup_date,
  country,
  referral_source
FROM deduplicated
WHERE row_num = 1

UNION ALL

SELECT 
  CONCAT('USR_', CAST((SELECT max_user_id FROM max_id) + dup_row_num AS STRING)) as user_id,
  first_name,
  last_name,
  email,
  signup_date,
  country,
  referral_source
FROM duplicates_numbered

ORDER BY signup_date

-- COMMAND ----------

-- DBTITLE 1,Silver Table Data 2
select * from dataengineering.video1.users_date_uidcleaned
order by user_id asc