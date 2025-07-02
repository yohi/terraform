SELECT
    date,
    log,
    container_name,
    ec2_instance_id
FROM ${database_name}."${table_name}"
WHERE partition_0 = '${year}' AND partition_1 = '${month}' AND partition_2 = '${day}'
    AND partition_4 = '${partition_4_value}'
    AND (
        LOWER(log) LIKE '%error%'
        OR LOWER(log) LIKE '%exception%'
        OR LOWER(log) LIKE '%traceback%'
        OR LOWER(log) LIKE '%internal server error%'
        OR regexp_extract(log, '\"[A-Z]+ [^\"]*\" ([45]\d{2})', 1) != ''
    )
ORDER BY date DESC
LIMIT 100
