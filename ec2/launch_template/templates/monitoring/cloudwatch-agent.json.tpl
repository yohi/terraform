{
  "agent": {
    "metrics_collection_interval": ${metrics_collection_interval},
    "run_as_user": "${run_as_user}"
  },
  "metrics": {
    "namespace": "${namespace}",
    "metrics_collected": {
      "cpu": ${cpu_metrics},
      "disk": {
        "measurement": ${disk_metrics},
        "metrics_collection_interval": ${metrics_collection_interval},
        "resources": ${disk_resources}
      },
      "diskio": {
        "measurement": ${diskio_metrics},
        "metrics_collection_interval": ${metrics_collection_interval}
      },
      "mem": {
        "measurement": ${mem_metrics},
        "metrics_collection_interval": ${metrics_collection_interval}
      }
    }%{ if enable_statsd ~},
    "statsd": {
      "metrics_aggregation_interval": 60,
      "metrics_collection_interval": 60,
      "service_address": ":${statsd_port}"
    }%{ endif ~}
  }
}
