SELECT
    date,
    container_id,
    container_name,
    source,
    log,
    ec2_instance_id,
    ecs_cluster,
    ecs_task_arn,
    ecs_task_definition,
    partition_0 as year,
    partition_1 as month,
    partition_2 as day,
    partition_3 as hour,
    partition_4
FROM ${database_name}."${table_name}"
WHERE
    partition_0 = '2025'
    AND partition_1 = '01'
    AND partition_2 = '17'
    AND (
        LOWER(log) LIKE '%critical%'
        OR LOWER(log) LIKE '%fatal%'
        OR LOWER(log) LIKE '%emergency%'
        OR LOWER(log) LIKE '%panic%'
        OR LOWER(log) LIKE '%error%'
        OR LOWER(log) LIKE '%exception%'
    )
ORDER BY date DESC
LIMIT 100
