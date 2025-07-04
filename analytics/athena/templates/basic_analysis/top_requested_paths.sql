SELECT
    regexp_extract(log, '"[A-Z]+ ([^"]+) ', 1) as request_path,
    COUNT(*) as request_count,
    COUNT(DISTINCT container_id) as containers_serving
FROM ${database_name}."${table_name}"
WHERE partition_0 = '${year}' AND partition_1 = '${month}' AND partition_2 = '${day}'
    AND partition_4 = '${partition_4_value}'
    AND month = '${month}'
    AND day = '${day}'
    AND log LIKE '%HTTP/1.1%'
GROUP BY regexp_extract(log, '"[A-Z]+ ([^"]+) ', 1)
ORDER BY request_count DESC
LIMIT 20
