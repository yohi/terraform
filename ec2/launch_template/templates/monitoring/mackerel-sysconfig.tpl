# Mackerel Agent Sysconfig Configuration
# This file is managed by Terraform

%{ if api_key != "" ~}
MACKEREL_API_KEY="${api_key}"
%{ endif ~}

%{ if organization != "" ~}
MACKEREL_ORGANIZATION="${organization}"
%{ endif ~}

%{ if roles != "" ~}
MACKEREL_ROLES="${roles}"
%{ endif ~}

%{ if auto_retirement != "" ~}
AUTO_RETIREMENT=${auto_retirement}
%{ endif ~}

# Additional environment variables
%{ for key, value in additional_env_vars ~}
${key}="${value}"
%{ endfor ~}

# Common Mackerel Agent settings
MACKEREL_AGENT_CONFIG="/etc/mackerel-agent/mackerel-agent.conf"
MACKEREL_AGENT_PIDFILE="/var/run/mackerel-agent.pid"
MACKEREL_AGENT_USER="mackerel-agent"

# Logging settings
MACKEREL_AGENT_LOG_LEVEL="info"
MACKEREL_AGENT_LOG_FILE="/var/log/mackerel-agent.log"

# Performance settings
MACKEREL_AGENT_MAX_DELAYED_METRICS="30"
