SELECT
    container_name,
    ec2_instance_id,
    ecs_cluster,
    COUNT(*) as log_count,
    MIN(`date`) as first_log,
    MAX(`date`) as last_log,
    COUNT(DISTINCT `hour`) as active_hours
FROM ${database_name}."${table_name}"
WHERE partition_0 = '${year}' AND partition_1 = '${month}' AND partition_2 = '${day}'
    AND partition_4 = '${partition_4_value}'
    AND month = '${month}'
    AND day = '${day}'
GROUP BY container_name, ec2_instance_id, ecs_cluster
ORDER BY log_count DESC
