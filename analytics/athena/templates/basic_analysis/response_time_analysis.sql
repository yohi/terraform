SELECT
    partition_3 as hour,
    COUNT(*) as request_count,
    AVG(CAST(regexp_extract(log, 'response_time:(\d+)', 1) AS DOUBLE)) as avg_response_time_ms,
    PERCENTILE_APPROX(CAST(regexp_extract(log, 'response_time:(\d+)', 1) AS DOUBLE), 0.5) as median_response_time_ms,
    PERCENTILE_APPROX(CAST(regexp_extract(log, 'response_time:(\d+)', 1) AS DOUBLE), 0.95) as p95_response_time_ms,
    MAX(CAST(regexp_extract(log, 'response_time:(\d+)', 1) AS DOUBLE)) as max_response_time_ms
FROM ${database_name}."${table_name}"
WHERE partition_0 = '2025' AND partition_1 = '01' AND partition_2 = '17'
    AND partition_4 = '${partition_4_value}'
    AND month = '01'
    AND day = '15'
    AND regexp_extract(log, 'response_time:(\d+)', 1) != ''
GROUP BY partition_3
ORDER BY partition_3
