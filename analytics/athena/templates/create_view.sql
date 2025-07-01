
CREATE OR REPLACE VIEW "${view_name}" AS
SELECT
    -- Parse timestamp from date field
    CASE
        WHEN date IS NOT NULL
        AND date != '' THEN CAST(date AS timestamp)
        ELSE NULL
    END AS parsed_timestamp,

CASE
    WHEN date IS NOT NULL
    AND date != '' THEN CAST(
        date_format(
            CAST(date AS timestamp),
            '%Y-%m-%d'
        ) AS date
    )
    ELSE NULL
END AS log_date,
CASE
    WHEN date IS NOT NULL
    AND date != '' THEN CAST(
        date_format(CAST(date AS timestamp), '%H') AS integer
    )
    ELSE NULL
END AS log_hour,

date AS original_date,
source,
log AS log_message,
container_id,
container_name,
ec2_instance_id,
ecs_cluster,
ecs_task_arn,
ecs_task_definition,

CASE
    WHEN source = 'stderr' THEN 'error'
    WHEN source = 'stdout' THEN 'info'
    ELSE 'unknown'
END AS log_level,

CASE
    WHEN log LIKE '%ERROR%'
    OR log LIKE '%error%' THEN 'error'
    WHEN log LIKE '%WARN%'
    OR log LIKE '%warn%' THEN 'warning'
    WHEN log LIKE '%INFO%'
    OR log LIKE '%info%' THEN 'info'
    WHEN log LIKE '%DEBUG%'
    OR log LIKE '%debug%' THEN 'debug'
    ELSE 'other'
END AS detected_log_level,


length(log) AS log_message_length

FROM ${database_name}."${table_name}"
WHERE
    -- Filter out empty or null log messages
    log IS NOT NULL
    AND log != ''
    -- Add date filter for performance (customize as needed)
    AND date IS NOT NULL
    AND date != ''
ORDER BY parsed_timestamp DESC
