WITH extracted_paths AS (
    SELECT
        regexp_extract(log, '\"[A-Z]+ ([^\"]*) HTTP', 1) as url_path
    FROM ${database_name}."${table_name}"
    WHERE partition_0 = '2025' AND partition_1 = '01' AND partition_2 = '17'
        AND partition_4 = '${partition_4_value}'
        AND log LIKE '%HTTP/%'
)
SELECT
    url_path,
    COUNT(*) as count
FROM extracted_paths
WHERE url_path IS NOT NULL AND url_path != ''
GROUP BY url_path
ORDER BY count DESC
LIMIT 20
