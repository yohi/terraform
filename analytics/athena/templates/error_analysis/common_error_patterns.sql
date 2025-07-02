SELECT
    regexp_extract(log, '(\w+Error|\w+Exception|\w+Fault)', 1) as error_type,
    COUNT(*) as count
FROM ${database_name}."${table_name}"
WHERE partition_0 = '${year}' AND partition_1 = '${month}' AND partition_2 = '${day}'
    AND partition_4 = '${partition_4_value}'
    AND regexp_extract(log, '(\w+Error|\w+Exception|\w+Fault)', 1) != ''
GROUP BY regexp_extract(log, '(\w+Error|\w+Exception|\w+Fault)', 1)
ORDER BY count DESC
LIMIT 20
