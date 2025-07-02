-- Simple Partition Check for Today's Data
-- This query checks if today's partitions exist and have data

SELECT
    COUNT(*) as record_count,
    partition_0 as year,
    partition_1 as month,
    partition_2 as day
FROM rcs_stg_web_logs."rcs-stg-django_web"
WHERE partition_0 = cast(year(current_date) as varchar)
    AND partition_1 = lpad(cast(month(current_date) as varchar), 2, '0')
    AND partition_2 = lpad(cast(day(current_date) as varchar), 2, '0')
    AND partition_4 = ''
GROUP BY partition_0, partition_1, partition_2
LIMIT 10;
