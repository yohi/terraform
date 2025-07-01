SELECT
    regexp_extract(log, '"([A-Z]+) ', 1) as http_method,
    COUNT(*) as count,
    COUNT(DISTINCT regexp_extract(log, '"[A-Z]+ ([^"]+) ', 1)) as unique_paths
FROM ${database_name}."${table_name}"
WHERE partition_0 = '2025' AND partition_1 = '01' AND partition_2 = '17'
    AND partition_4 = '${partition_4_value}'
    AND month = '01'
    AND day = '15'
    AND log LIKE '%HTTP/1.1%'
GROUP BY regexp_extract(log, '"([A-Z]+) ', 1)
ORDER BY count DESC
