-- Log Count by Hour Analysis
-- This query counts logs by hour along with unique container and instance counts
--
-- TROUBLESHOOTING: If you encounter "COLUMN_NOT_FOUND: Column 'partition_0' cannot be resolved" error,
-- run this command first: MSCK REPAIR TABLE ${database_name}."${table_name}";

SELECT
    partition_0 as year,
    partition_1 as month,
    partition_2 as day,
    partition_3 as hour,
    COUNT(*) as log_count,
    COUNT(DISTINCT container_id) as unique_containers,
    COUNT(DISTINCT ec2_instance_id) as unique_instances
FROM ${database_name}."${table_name}"
WHERE partition_0 = cast(year(now()) as varchar)
    AND partition_1 = lpad(cast(month(now()) as varchar), 2, '0')
    AND partition_2 = lpad(cast(day(now()) as varchar), 2, '0')
    AND partition_4 = '${partition_4_value}'
GROUP BY partition_0, partition_1, partition_2, partition_3, partition_4
ORDER BY partition_0, partition_1, partition_2, partition_3, partition_4
