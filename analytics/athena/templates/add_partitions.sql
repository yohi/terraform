SHOW PARTITIONS ${database_name}.${table_name}

-- Partition Management Commands
-- Use these commands to discover and repair partitions when encountering
-- "COLUMN_NOT_FOUND: Column 'partition_0' cannot be resolved" errors

-- 1. Repair partitions (discovers new partitions from S3)
MSCK REPAIR TABLE ${database_name}."${table_name}";

-- 2. Verify partitions were added successfully
SHOW PARTITIONS ${database_name}."${table_name}" LIMIT 10;

-- 3. Alternative: Check table structure
-- DESCRIBE ${database_name}."${table_name}";

-- Note: MSCK REPAIR TABLE command scans the S3 location and automatically
-- adds partition metadata to the table for any partitions that exist in S3
-- but are not registered in the Glue catalog.

-- Add partitions to table
-- This script helps add specific partitions manually when automatic discovery fails
--
-- ===========================================
-- PARTITION REPAIR COMMANDS
-- ===========================================
--
-- If you encounter "COLUMN_NOT_FOUND: Column 'partition_0' cannot be resolved" error,
-- run these commands first:
--
-- For ${project_env} environment tables:
-- 1. Check current partitions
-- SHOW PARTITIONS ${database_name}."${project_env}-django_web" LIMIT 5;
-- SHOW PARTITIONS ${database_name}."${project_env}-nginx_web" LIMIT 5;
-- SHOW PARTITIONS ${database_name}."${project_env}-error" LIMIT 5;
--
-- 2. Repair partitions (run each command separately)
-- MSCK REPAIR TABLE ${database_name}."${project_env}-django_web";
-- MSCK REPAIR TABLE ${database_name}."${project_env}-nginx_web";
-- MSCK REPAIR TABLE ${database_name}."${project_env}-error";
--
-- 3. Verify partitions were added
-- SHOW PARTITIONS ${database_name}."${project_env}-django_web" LIMIT 10;
-- SHOW PARTITIONS ${database_name}."${project_env}-nginx_web" LIMIT 10;
-- SHOW PARTITIONS ${database_name}."${project_env}-error" LIMIT 10;
--
-- ===========================================
-- MANUAL PARTITION ADDITION (if MSCK REPAIR doesn't work)
-- ===========================================

-- Add partition for current date
ALTER TABLE ${database_name}."${table_name}"
ADD PARTITION (
    partition_0='${year}',
    partition_1='${month}',
    partition_2='${day}',
    partition_3='${hour}',
    partition_4='${partition_4_value}'
)
LOCATION 's3://${bucket_name}/${s3_prefix}/year=${year}/month=${month}/day=${day}/hour=${hour}/';
