WITH status_counts AS (
    SELECT
        regexp_extract(log, '\"[A-Z]+ [^\"]*\" (\d+)', 1) as status_code,
        COUNT(*) as count
    FROM ${database_name}."${table_name}"
    WHERE partition_0 = '2025' AND partition_1 = '01' AND partition_2 = '17'
        AND partition_4 = '${partition_4_value}'
        AND log LIKE '%HTTP/1.1%'
    GROUP BY regexp_extract(log, '\"[A-Z]+ [^\"]*\" (\d+)', 1)
)
SELECT
    status_code,
    count,
    ROUND(count * 100.0 / SUM(count) OVER(), 2) as percentage
FROM status_counts
ORDER BY count DESC
