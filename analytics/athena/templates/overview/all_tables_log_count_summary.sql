
%{~ for table_name in table_names ~}
SELECT
    '${table_name}' as table_name,
    partition_0 as year, partition_1 as month, partition_2 as day, partition_3 as hour,
    COUNT(*) as log_count
FROM ${database_name}."${table_name}"
WHERE partition_0 = cast(year(now()) as varchar) AND partition_1 = lpad(cast(month(now()) as varchar), 2, '0') AND partition_2 = lpad(cast(day(now()) as varchar), 2, '0')
    AND partition_4 = '${partition_4_value}'
GROUP BY partition_0, partition_1, partition_2, partition_3, partition_4
%{~ if table_name != table_names[length(table_names)-1] ~}

UNION ALL

%{~ endif ~}
%{~ endfor ~}
ORDER BY table_name, partition_0, partition_1, partition_2, partition_3
