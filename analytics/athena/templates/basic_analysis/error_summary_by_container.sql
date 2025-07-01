SELECT
    container_name,
    ec2_instance_id,
    COUNT(*) as error_count,
    MIN(date) as first_error,
    MAX(date) as last_error
FROM ${database_name}."${table_name}"
WHERE partition_0 = '2025' AND partition_1 = '01' AND partition_2 = '17'
    AND partition_4 = '${partition_4_value}'
    AND month = '01'
    AND day = '15'
    AND (
        LOWER(log) LIKE '%error%'
        OR LOWER(log) LIKE '%exception%'
        OR regexp_extract(log, '"[A-Z]+ [^"]*" ([45]\d{2})', 1) != ''
    )
GROUP BY container_name, ec2_instance_id
ORDER BY error_count DESC
