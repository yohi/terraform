-- Recent Logs Sample Query
-- This query retrieves the most recent log entries from the specified table
--
-- TROUBLESHOOTING: If you encounter "COLUMN_NOT_FOUND: Column 'partition_0' cannot be resolved" error,
-- run this command first: MSCK REPAIR TABLE ${database_name}."${table_name}";

SELECT
    date,
    source,
    log,
    container_name,
    ec2_instance_id
FROM ${database_name}."${table_name}"
WHERE partition_0 = cast(year(current_timestamp) as varchar)
    AND partition_1 = lpad(cast(month(current_timestamp) as varchar), 2, '0')
    AND partition_2 = lpad(cast(day(current_timestamp) as varchar), 2, '0')
    AND partition_4 = '${partition_4_value}'
    AND month = lpad(cast(month(current_timestamp) as varchar), 2, '0')
    AND day = lpad(cast(day(current_timestamp) as varchar), 2, '0')
    AND hour >= lpad(cast(hour(current_timestamp - interval '1' hour) as varchar), 2, '0')
ORDER BY date DESC
LIMIT 100
