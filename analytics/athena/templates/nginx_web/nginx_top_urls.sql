WITH extracted_paths AS (
    SELECT
        regexp_extract(log, '\"[A-Z]+ ([^\"]*) HTTP', 1) as url_path
    FROM ${database_name}."${table_name}"
    WHERE partition_0 = '${year}' AND partition_1 = '${month}' AND partition_2 = '${day}'
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
