SELECT
    partition_3 as hour,
    COUNT(*) as total_logs,
    COUNT(CASE WHEN log LIKE '%HTTP/1.1%' THEN 1 END) as http_requests,
    COUNT(DISTINCT container_id) as active_containers,
    COUNT(DISTINCT ec2_instance_id) as active_instances
FROM ${database_name}."${table_name}"
WHERE partition_0 = '2025' AND partition_1 = '01' AND partition_2 = '17'
    AND partition_4 = '${partition_4_value}'
    AND month = '01'
    AND day = '15'
GROUP BY partition_3
ORDER BY partition_3
