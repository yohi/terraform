SELECT
    regexp_extract(log, '"[A-Z]+ ([^"]*) HTTP', 1) as url_path,
    COUNT(*) as count
FROM ${database_name}."${table_name}"
WHERE partition_0 = '${year}' AND partition_1 = '${month}' AND partition_2 = '${day}'
    AND partition_4 = '${partition_4_value}'
    AND log LIKE '%HTTP/1.1%'
GROUP BY regexp_extract(log, '"[A-Z]+ ([^"]*) HTTP', 1)
ORDER BY count DESC
LIMIT 20
