SELECT
    regexp_extract(log, '"[A-Z]+ ([^"]+) ', 1) as request_path,
    COUNT(*) as request_count,
    COUNT(DISTINCT container_id) as containers_serving
FROM ${database_name}."${table_name}"
WHERE partition_0 = '2025' AND partition_1 = '01' AND partition_2 = '17'
    AND partition_4 = '${partition_4_value}'
    AND month = '01'
    AND day = '15'
    AND log LIKE '%HTTP/1.1%'
GROUP BY regexp_extract(log, '"[A-Z]+ ([^"]+) ', 1)
ORDER BY request_count DESC
LIMIT 20
