# Mackerel Agent Configuration
apikey = "${api_key}"
display_name = "${display_name}"

# Roles configuration
%{ if roles != "" ~}
roles = [%{ for role in split(",", roles) ~}"${trimspace(role)}"%{ if role != element(split(",", roles), length(split(",", roles)) - 1) ~}, %{ endif ~}%{ endfor ~}]
%{ endif ~}

# File system check plugins
[plugin.checks.filesystem]
command = "mackerel-plugin-disk -c 90 -w 80"

# Load average check
[plugin.checks.load]
command = "mackerel-plugin-load -c 5 -w 3"

# Memory usage metrics
[plugin.metrics.memory]
command = "mackerel-plugin-memory"

# Disk usage metrics
[plugin.metrics.disk]
command = "mackerel-plugin-disk"

# Network interface metrics
[plugin.metrics.interface]
command = "mackerel-plugin-interface"
