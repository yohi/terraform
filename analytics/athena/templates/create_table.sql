
CREATE EXTERNAL TABLE IF NOT EXISTS ${database_name}."${table_name}" (
%{~ for field_name, field_config in schema_fields ~}
  "${field_name}" ${field_config.type}%{~ if field_config.description != "" ~} COMMENT '${field_config.description}'%{~ endif ~}%{~ if field_name != keys(schema_fields)[length(keys(schema_fields))-1] ~},%{~ endif ~}
%{~ endfor ~}
)
COMMENT 'External table for ${table_name} logs with Glue Crawler partitions'
PARTITIONED BY (
  "partition_0" string COMMENT 'Year partition (YYYY)',
  "partition_1" string COMMENT 'Month partition (MM)',
  "partition_2" string COMMENT 'Day partition (DD)',
  "partition_3" string COMMENT 'Hour partition (HH)',
  "partition_4" string COMMENT 'Additional partition level'
)
STORED AS INPUTFORMAT 'org.apache.hadoop.mapred.TextInputFormat'
OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
WITH SERDEPROPERTIES (
  'serialization.format' = '1',
  'ignore.malformed.json' = 'TRUE',
  'dots.in.keys' = 'FALSE',
  'case.insensitive' = 'TRUE',
  'mapping' = 'TRUE'
)
LOCATION '${s3_location}'
TBLPROPERTIES (
  -- Table properties for better performance
  'has_encrypted_data'='false',
  'compressionType'='none',
  'classification'='json',
  'typeOfData'='file'
)
