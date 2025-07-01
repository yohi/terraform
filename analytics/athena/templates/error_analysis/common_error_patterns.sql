SELECT
    regexp_extract(log, '(\w+Error|\w+Exception|\w+Fault)', 1) as error_type,
    COUNT(*) as count
FROM ${database_name}."${table_name}"
WHERE partition_0 = '2025' AND partition_1 = '01' AND partition_2 = '17'
    AND partition_4 = '${partition_4_value}'
    AND regexp_extract(log, '(\w+Error|\w+Exception|\w+Fault)', 1) != ''
GROUP BY regexp_extract(log, '(\w+Error|\w+Exception|\w+Fault)', 1)
ORDER BY count DESC
LIMIT 20
