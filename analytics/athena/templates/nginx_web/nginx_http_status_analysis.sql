SELECT
    regexp_extract(log, ' (\d{3}) ', 1) as status_code,
    COUNT(*) as count
FROM ${database_name}."${table_name}"
WHERE partition_0 = '2025' AND partition_1 = '01' AND partition_2 = '17'
    AND partition_4 = '${partition_4_value}'
    AND log RLIKE '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}'
GROUP BY regexp_extract(log, ' (\d{3}) ', 1)
ORDER BY count DESC
