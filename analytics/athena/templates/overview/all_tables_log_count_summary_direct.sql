-- Log Count Summary Query for All Tables (Direct Execution)
-- Tables: rcs-stg-django_web, rcs-stg-error, rcs-stg-nginx_web
-- Database: rcs_stg_web_logs
-- This query shows log counts by hour for today's date


SELECT
    'rcs-stg-django_web' as table_name,
    partition_0 as year,
    partition_1 as month,
    partition_2 as day,
    partition_3 as hour,
    COUNT(*) as log_count
FROM rcs_stg_web_logs."rcs-stg-django_web"
WHERE partition_0 = cast(year(current_date) as varchar)
    AND partition_1 = lpad(cast(month(current_date) as varchar), 2, '0')
    AND partition_2 = lpad(cast(day(current_date) as varchar), 2, '0')
    AND partition_4 = ''
GROUP BY partition_0, partition_1, partition_2, partition_3

UNION ALL

SELECT
    'rcs-stg-error' as table_name,
    partition_0 as year,
    partition_1 as month,
    partition_2 as day,
    partition_3 as hour,
    COUNT(*) as log_count
FROM rcs_stg_web_logs."rcs-stg-error"
WHERE partition_0 = cast(year(current_date) as varchar)
    AND partition_1 = lpad(cast(month(current_date) as varchar), 2, '0')
    AND partition_2 = lpad(cast(day(current_date) as varchar), 2, '0')
    AND partition_4 = ''
GROUP BY partition_0, partition_1, partition_2, partition_3

UNION ALL

SELECT
    'rcs-stg-nginx_web' as table_name,
    partition_0 as year,
    partition_1 as month,
    partition_2 as day,
    partition_3 as hour,
    COUNT(*) as log_count
FROM rcs_stg_web_logs."rcs-stg-nginx_web"
WHERE partition_0 = cast(year(current_date) as varchar)
    AND partition_1 = lpad(cast(month(current_date) as varchar), 2, '0')
    AND partition_2 = lpad(cast(day(current_date) as varchar), 2, '0')
    AND partition_4 = ''
GROUP BY partition_0, partition_1, partition_2, partition_3

ORDER BY table_name, year, month, day, hour;
