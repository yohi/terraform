-- Partition Repair Guide
-- Use this template when encountering partition-related errors
--
-- ===========================================
-- GENERAL TEMPLATE (for single table repair)
-- ===========================================
--
-- STEP 1: Check if partitions exist
SHOW PARTITIONS ${database_name}."${table_name}" LIMIT 5;

-- STEP 2: If no partitions are found, repair them
-- This command scans S3 and adds missing partition metadata
MSCK REPAIR TABLE ${database_name}."${table_name}";

-- STEP 3: Verify partitions were added
SHOW PARTITIONS ${database_name}."${table_name}" LIMIT 10;

-- STEP 4: Check table structure (optional)
DESCRIBE ${database_name}."${table_name}";

-- STEP 5: Test with a simple query
SELECT COUNT(*) as total_records
FROM ${database_name}."${table_name}"
WHERE partition_0 = cast(year(now()) as varchar)
    AND partition_1 = lpad(cast(month(now()) as varchar), 2, '0')
    AND partition_2 = lpad(cast(day(now()) as varchar), 2, '0')
    AND partition_4 = '${partition_4_value}'
LIMIT 1;

-- ===========================================
-- SPECIFIC EXAMPLE FOR ALL TABLES REPAIR
-- (Replace ${project_env} with your actual prefix, e.g., "rcs-stg")
-- ===========================================
--
-- Step 1: Check partitions for all tables
-- SHOW PARTITIONS ${database_name}."${project_env}-django_web" LIMIT 5;
-- SHOW PARTITIONS ${database_name}."${project_env}-nginx_web" LIMIT 5;
-- SHOW PARTITIONS ${database_name}."${project_env}-error" LIMIT 5;
--
-- Step 2: Repair all tables (run each command separately)
-- MSCK REPAIR TABLE ${database_name}."${project_env}-django_web";
-- MSCK REPAIR TABLE ${database_name}."${project_env}-nginx_web";
-- MSCK REPAIR TABLE ${database_name}."${project_env}-error";
--
-- Step 3: Verify all partitions were added
-- SHOW PARTITIONS ${database_name}."${project_env}-django_web" LIMIT 10;
-- SHOW PARTITIONS ${database_name}."${project_env}-nginx_web" LIMIT 10;
-- SHOW PARTITIONS ${database_name}."${project_env}-error" LIMIT 10;

-- COMMON ERRORS AND SOLUTIONS:
--
-- Error: "COLUMN_NOT_FOUND: Column 'partition_0' cannot be resolved"
-- Solution: Run MSCK REPAIR TABLE command above
--
-- Error: "Table not found"
-- Solution: Check database name and table name, ensure table is created
--
-- Error: "No partitions found"
-- Solution: Verify S3 data exists and path structure matches partition schema
--
-- Error: "Access denied" or "Permission denied"
-- Solution: Check IAM permissions for S3 bucket and Glue Catalog access

-- Partition Repair Commands for All Tables
-- Run these commands BEFORE executing the overview query if you encounter partition errors
--
-- These commands will discover and add new partitions from S3 to the table metadata.
-- Execute each command individually and wait for completion before running the next one.

-- Step 1: Check current partitions for each table
-- Uncomment and run one by one to check current partition status:

-- SHOW PARTITIONS ${database_name}."${project_env}-django_web" LIMIT 5;
-- SHOW PARTITIONS ${database_name}."${project_env}-nginx_web" LIMIT 5;
-- SHOW PARTITIONS ${database_name}."${project_env}-error" LIMIT 5;

-- Step 2: Repair partitions (run each command separately)
-- Uncomment and execute one by one:

-- MSCK REPAIR TABLE ${database_name}."${project_env}-django_web";
-- MSCK REPAIR TABLE ${database_name}."${project_env}-nginx_web";
-- MSCK REPAIR TABLE ${database_name}."${project_env}-error";

-- Step 3: Verify partitions were added
-- Uncomment and run to verify:

-- SHOW PARTITIONS ${database_name}."${project_env}-django_web" LIMIT 10;
-- SHOW PARTITIONS ${database_name}."${project_env}-nginx_web" LIMIT 10;
-- SHOW PARTITIONS ${database_name}."${project_env}-error" LIMIT 10;

-- If you need to repair specific partitions, you can also use:
-- ALTER TABLE ${database_name}."${project_env}-django_web" ADD PARTITION (partition_0='${year}', partition_1='${month}', partition_2='${day}', partition_3='${hour}', partition_4='');
