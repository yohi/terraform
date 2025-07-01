SELECT
    CONCAT(year, '-', LPAD(month, 2, '0'), '-', LPAD(day, 2, '0')) as date,
    COUNT(*) as daily_log_count,
    COUNT(DISTINCT container_id) as unique_containers_per_day
FROM ${database_name}."${table_name}"
WHERE partition_0 = '2025' AND partition_1 = '01' AND partition_2 = '17'
    AND partition_4 = '${partition_4_value}'
    AND month = '01'
    AND day BETWEEN '10' AND '15'
GROUP BY year, month, day
ORDER BY year, month, day
