SELECT
    date,
    container_name,
    source,
    log,
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
FROM ${database_name}."${table_name}"
WHERE
    partition_0 = '2025'
    AND partition_1 = '01'
ORDER BY date DESC
LIMIT 1000
