SELECT
    partition_0 as year, partition_1 as month, partition_2 as day, partition_3 as hour,
    COUNT(*) as log_count
FROM ${database_name}."${table_name}"
WHERE partition_0 = '${year}' AND partition_1 = '${month}' AND partition_2 = '${day}'
    AND partition_4 = '${partition_4_value}'
GROUP BY partition_0, partition_1, partition_2, partition_3, partition_4
ORDER BY partition_0, partition_1, partition_2, partition_3, partition_4
