
SELECT
    date,
    source,
    log,
    container_name,
    ec2_instance_id
FROM ${database_name}."${table_name}"
WHERE
    year = '2025'
    AND month = '06'
    AND day = '25'
ORDER BY date DESC
LIMIT 50
