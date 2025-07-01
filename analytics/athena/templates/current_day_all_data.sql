
SELECT
    'django_web' as log_type,
    date as timestamp,
    source,
    log as message,
    container_name,
    container_id,
    ec2_instance_id,
    ecs_cluster,
    ecs_task_arn,
    ecs_task_definition,
    partition_0 as year,
    partition_1 as month,
    partition_2 as day,
    partition_3 as hour,
    partition_4
FROM ${database_name}."${django_web_table}"
WHERE
    partition_0 = cast(year(now()) as varchar)
    AND partition_1 = lpad(cast(month(now()) as varchar), 2, '0')
    AND partition_2 = lpad(cast(day(now()) as varchar), 2, '0')

UNION ALL

SELECT
    'nginx_web' as log_type,
    date as timestamp,
    source,
    log as message,
    container_name,
    container_id,
    ec2_instance_id,
    ecs_cluster,
    ecs_task_arn,
    ecs_task_definition,
    partition_0 as year,
    partition_1 as month,
    partition_2 as day,
    partition_3 as hour,
    partition_4
FROM ${database_name}."${nginx_web_table}"
WHERE
    partition_0 = cast(year(now()) as varchar)
    AND partition_1 = lpad(cast(month(now()) as varchar), 2, '0')
    AND partition_2 = lpad(cast(day(now()) as varchar), 2, '0')

UNION ALL

SELECT
    'error' as log_type,
    date as timestamp,
    source,
    log as message,
    container_name,
    container_id,
    ec2_instance_id,
    ecs_cluster,
    ecs_task_arn,
    ecs_task_definition,
    partition_0 as year,
    partition_1 as month,
    partition_2 as day,
    partition_3 as hour,
    partition_4
FROM ${database_name}."${error_table}"
WHERE
    partition_0 = cast(year(now()) as varchar)
    AND partition_1 = lpad(cast(month(now()) as varchar), 2, '0')
    AND partition_2 = lpad(cast(day(now()) as varchar), 2, '0')

ORDER BY timestamp DESC, log_type
LIMIT 1000
