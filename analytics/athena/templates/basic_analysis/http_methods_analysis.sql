SELECT
    regexp_extract(log, '"([A-Z]+) ', 1) as http_method,
    COUNT(*) as count,
    COUNT(DISTINCT regexp_extract(log, '"[A-Z]+ ([^"]+) ', 1)) as unique_paths
FROM ${database_name}."${table_name}"
WHERE partition_0 = '${year}' AND partition_1 = '${month}' AND partition_2 = '${day}'
AND partition_4 = '${partition_4_value}'
AND month = '${month}'
AND day = '${day}'
    AND log LIKE '%HTTP/1.1%'
GROUP BY regexp_extract(log, '"([A-Z]+) ', 1)
ORDER BY count DESC
