SELECT
    date,
    source,
    log,
    container_name,
    ec2_instance_id
FROM ${database_name}."${table_name}"
WHERE partition_0 = '2025' AND partition_1 = '01' AND partition_2 = '17'
    AND partition_4 = '${partition_4_value}'
    AND month = '01'
    AND day = '15'
    AND hour = '23'
ORDER BY date DESC
LIMIT 100
