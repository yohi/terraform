SELECT
    partition_3 as hour,
    COUNT(*) as requests_count,
    COUNT(DISTINCT container_id) as active_containers,
    COUNT(DISTINCT ec2_instance_id) as active_instances
FROM ${database_name}."${table_name}"
WHERE partition_0 = '2025' AND partition_1 = '01' AND partition_2 = '17'
    AND partition_4 = '${partition_4_value}'
    AND log LIKE '%HTTP/1.1%'
GROUP BY partition_3
ORDER BY CAST(partition_3 AS int)
