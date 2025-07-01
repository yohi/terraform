SELECT
    CASE
        WHEN LOWER(log) LIKE '%critical%' OR LOWER(log) LIKE '%fatal%' THEN 'CRITICAL'
        WHEN LOWER(log) LIKE '%error%' THEN 'ERROR'
        WHEN LOWER(log) LIKE '%warning%' OR LOWER(log) LIKE '%warn%' THEN 'WARNING'
        ELSE 'OTHER'
    END as error_level,
    COUNT(*) as count
FROM ${database_name}."${table_name}"
WHERE partition_0 = '2025' AND partition_1 = '01' AND partition_2 = '17'
    AND partition_4 = '${partition_4_value}'
GROUP BY CASE
    WHEN LOWER(log) LIKE '%critical%' OR LOWER(log) LIKE '%fatal%' THEN 'CRITICAL'
    WHEN LOWER(log) LIKE '%error%' THEN 'ERROR'
    WHEN LOWER(log) LIKE '%warning%' OR LOWER(log) LIKE '%warn%' THEN 'WARNING'
    ELSE 'OTHER'
END
ORDER BY count DESC
