SELECT
    container_name,
    ec2_instance_id,
    ecs_cluster,
    COUNT(*) as log_count,
    MIN(date) as first_log,
    MAX(date) as last_log,
    COUNT(DISTINCT hour) as active_hours
FROM ${database_name}."${table_name}"
WHERE partition_0 = '2025' AND partition_1 = '01' AND partition_2 = '17'
    AND partition_4 = '${partition_4_value}'
    AND month = '01'
    AND day = '15'
GROUP BY container_name, ec2_instance_id, ecs_cluster
ORDER BY log_count DESC
