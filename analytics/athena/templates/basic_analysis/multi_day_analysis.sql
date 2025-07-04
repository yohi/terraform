SELECT
    CONCAT(year, '-', LPAD(month, 2, '0'), '-', LPAD(day, 2, '0')) as date,
    COUNT(*) as daily_log_count,
    COUNT(DISTINCT container_id) as unique_containers_per_day
FROM ${database_name}."${table_name}"
WHERE partition_0 = '${year}' AND partition_1 = '${month}'
    AND partition_4 = '${partition_4_value}'
    AND month = '${month}'
    AND day BETWEEN '${start_day}' AND '${end_day}'
GROUP BY year, month, day
ORDER BY year, month, day
