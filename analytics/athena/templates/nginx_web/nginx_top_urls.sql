SELECT
    regexp_extract(log, '\"[A-Z]+ ([^\"]*) HTTP', 1) as url_path,
    COUNT(*) as count
FROM ${database_name}."${table_name}"
WHERE partition_0 = '2025' AND partition_1 = '01' AND partition_2 = '17'
    AND partition_4 = '${partition_4_value}'
    AND log LIKE '%HTTP/%'
GROUP BY regexp_extract(log, '\"[A-Z]+ ([^\"]*) HTTP', 1)
ORDER BY count DESC
LIMIT 20
