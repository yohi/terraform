-- Table Structure and Partition Check Queries
-- Use these queries to diagnose table structure and partition issues

-- 1. Check if tables exist and their structure
-- Run these queries to see the table schema and available columns:

-- DESCRIBE ${database_name}."${project_env}-django_web";
-- DESCRIBE ${database_name}."${project_env}-nginx_web";
-- DESCRIBE ${database_name}."${project_env}-error";

-- 2. Check table location and format
-- SHOW CREATE TABLE ${database_name}."${project_env}-django_web";

-- 3. List all tables in the database
-- SHOW TABLES IN ${database_name};

-- 4. Check if partition columns exist
-- SELECT column_name, data_type
-- FROM information_schema.columns
-- WHERE table_schema = '${database_name}'
--   AND table_name = '${project_env}-django_web'
--   AND column_name LIKE 'partition_%';

-- 5. Simple data existence check (without partitions)
-- SELECT COUNT(*) as total_records FROM ${database_name}."${project_env}-django_web" LIMIT 1;
-- SELECT COUNT(*) as total_records FROM ${database_name}."${project_env}-nginx_web" LIMIT 1;
-- SELECT COUNT(*) as total_records FROM ${database_name}."${project_env}-error" LIMIT 1;

-- 6. Sample data check
-- SELECT * FROM ${database_name}."${project_env}-django_web" LIMIT 5;

-- 7. Check S3 location for the table
-- SELECT input_format, output_format, location
-- FROM information_schema.tables
-- WHERE table_schema = '${database_name}'
--   AND table_name = '${project_env}-django_web';

-- 8. Alternative overview query without partitions (if partition columns don't exist)
-- Use this if partition_0, partition_1, etc. columns are not found:
/*
%{~ for table_name in table_names ~}
SELECT
    '${table_name}' as table_name,
    COUNT(*) as total_log_count,
    MIN(log_time) as earliest_log,
    MAX(log_time) as latest_log
FROM ${database_name}."${table_name}"
%{~ if table_name != table_names[length(table_names)-1] ~}
UNION ALL
%{~ endif ~}
%{~ endfor ~}
ORDER BY table_name;
*/
