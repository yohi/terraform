#!/bin/bash
# ==================================================
# EC2 User Data Script
# ==================================================

# エラー処理の設定
set -euo pipefail

# ログ出力関数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a /var/log/user-data.log
}

log "EC2 User Data Script started"

# ==================================================
# AWS基本設定
# ==================================================

# AWS デフォルトリージョン設定
export AWS_DEFAULT_REGION=${aws_region}
log "AWS_DEFAULT_REGION set to: ${aws_region}"

# ==================================================
# ECS設定
# ==================================================

%{ if ecs_cluster_name != "" }
log "Configuring ECS settings"

# ECS 設定
echo ECS_CLUSTER=${ecs_cluster_name} >> /etc/ecs/ecs.config
echo ECS_ENGINE_TASK_CLEANUP_WAIT_DURATION=3m >> /etc/ecs/ecs.config
echo ECS_IMAGE_CLEANUP_INTERVAL=10m >> /etc/ecs/ecs.config
echo ECS_IMAGE_MINIMUM_CLEANUP_AGE=30m >> /etc/ecs/ecs.config
echo ECS_NUM_IMAGES_DELETE_PER_CYCLE=10 >> /etc/ecs/ecs.config
echo ECS_CONTAINER_STOP_TIMEOUT=30s >> /etc/ecs/ecs.config

%{ if ecs_app_type != "" }
echo ECS_INSTANCE_ATTRIBUTES="{\"APP_TYPE\": \"${ecs_app_type}\"}" >> /etc/ecs/ecs.config
log "ECS instance attributes set for APP_TYPE: ${ecs_app_type}"
%{ endif }

log "ECS configuration completed for cluster: ${ecs_cluster_name}"
%{ endif }

# ==================================================
# ツールのインストール
# ==================================================

log "Installing monitoring tools"

# CTOP インストール
if ! command -v ctop &> /dev/null; then
    log "Installing ctop v${ctop_version}"
    sudo curl -Lo /usr/local/bin/ctop https://github.com/bcicen/ctop/releases/download/v${ctop_version}/ctop-${ctop_version}-linux-amd64
    sudo chmod +x /usr/local/bin/ctop
    log "ctop installation completed"
else
    log "ctop is already installed"
fi

# CloudWatch Agent インストール
if ! command -v amazon-cloudwatch-agent-ctl &> /dev/null; then
    log "Installing CloudWatch Agent"
    sudo yum install -y amazon-cloudwatch-agent
    log "CloudWatch Agent installation completed"
else
    log "CloudWatch Agent is already installed"
fi

# ==================================================
# CloudWatch Agent設定
# ==================================================

%{ if cloudwatch_agent_config != "" }
log "Configuring CloudWatch Agent with config: ${cloudwatch_agent_config}"

# SSMパラメータの存在確認
if aws ssm get-parameter --name "${cloudwatch_agent_config}" --query 'Parameter.Value' --output text > /dev/null 2>&1; then
    log "CloudWatch Agent configuration found in Parameter Store"

    # CloudWatch Agent設定の取得と開始
    if sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
        -a fetch-config -m ec2 -s -c ssm:${cloudwatch_agent_config}; then
        log "CloudWatch Agent started successfully"
    else
        log "ERROR: Failed to start CloudWatch Agent with configuration from Parameter Store"
    fi
else
    log "WARNING: CloudWatch Agent configuration parameter '${cloudwatch_agent_config}' not found in Parameter Store, skipping CloudWatch Agent configuration"
fi
%{ endif }

# ==================================================
# Mackerel Agent設定
# ==================================================

%{ if mackerel_api_key != "" }
log "Installing Mackerel Agent"
curl -fsSL https://mackerel.io/file/script/amznlinux/setup-all-yum-v2.sh | MACKEREL_APIKEY='${mackerel_api_key}' sh
log "Mackerel Agent installation completed"
%{ endif }

%{ if mackerel_parameter_prefix != "" }
log "Configuring Mackerel Agent from Parameter Store"

# sysconfig設定の取得
if aws ssm get-parameter --name "${mackerel_parameter_prefix}agent" --query 'Parameter.Value' --output text > /etc/sysconfig/mackerel-agent 2>/dev/null; then
    log "Mackerel sysconfig loaded from Parameter Store"
else
    log "Mackerel sysconfig not found in Parameter Store, creating default"
    touch /etc/sysconfig/mackerel-agent
fi



# エージェント設定ファイルの取得
if aws ssm get-parameter --name "${mackerel_parameter_prefix}api-conf" --query 'Parameter.Value' --output text > /etc/mackerel-agent/mackerel-agent.conf 2>/dev/null; then
    log "Mackerel agent configuration loaded from Parameter Store"

    # 設定ファイルの権限設定
    sudo chown mackerel-agent:mackerel-agent /etc/mackerel-agent/mackerel-agent.conf
    sudo chmod 640 /etc/mackerel-agent/mackerel-agent.conf

    # サービス再起動
    sudo systemctl restart mackerel-agent
    log "Mackerel agent restarted with new configuration"
else
    log "Mackerel agent configuration not found in Parameter Store, using default"
fi

log "Mackerel Agent configuration completed"
%{ endif }

# ==================================================
# カスタムユーザーデータの実行
# ==================================================

%{ if custom_user_data != "" }
log "Executing custom user data"

# カスタムユーザーデータのサニタイゼーション関数
sanitize_user_data() {
    local user_data="$1"

    # 危険なコマンドのブラックリスト
    local dangerous_commands=(
        "rm -rf"
        "format"
        "mkfs"
        "dd if="
        "shutdown"
        "reboot"
        "halt"
        "init 0"
        "init 6"
        "> /dev/"
        "curl.*|.*sh"
        "wget.*|.*sh"
        "eval"
        "exec"
        "|sh"
        "|bash"
        "&& sh"
        "&& bash"
        ";sh"
        ";bash"
    )

    # 危険なコマンドの検出
    for cmd in "$${dangerous_commands[@]}"; do
        if [[ "$user_data" =~ $cmd ]]; then
            log "ERROR: Dangerous command detected in custom_user_data: $cmd"
            log "Custom user data execution blocked for security reasons"
            return 1
        fi
    done

    # 許可されたコマンドのホワイトリスト（必要に応じて拡張）
    local allowed_commands=(
        "echo"
        "mkdir"
        "chmod"
        "chown"
        "cp"
        "mv"
        "ln"
        "touch"
        "systemctl"
        "service"
        "yum install"
        "apt install"
        "pip install"
        "export"
        "source"
    )

    # 基本的なコマンド形式の検証
    if [[ ! "$user_data" =~ ^[a-zA-Z0-9_./\-[:space:]=\"\'\$\{\}]+$ ]]; then
        log "ERROR: Invalid characters detected in custom_user_data"
        log "Custom user data execution blocked for security reasons"
        return 1
    fi

    return 0
}

# カスタムユーザーデータの安全な実行
execute_custom_user_data() {
    local user_data='${custom_user_data}'

    # 空でない場合のみ処理
    if [[ -n "$user_data" ]]; then
        log "Validating custom user data for security"

        # サニタイゼーション実行
        if sanitize_user_data "$user_data"; then
            log "Custom user data validation passed"

            # 一時ファイルに書き込み
            local temp_script="/tmp/custom_user_data_$$.sh"
            echo "#!/bin/bash" > "$temp_script"
            echo "set -euo pipefail" >> "$temp_script"
            echo "$user_data" >> "$temp_script"

            # 実行権限を付与
            chmod 755 "$temp_script"

            # 実行
            if bash "$temp_script"; then
                log "Custom user data executed successfully"
            else
                log "ERROR: Custom user data execution failed"
            fi

            # 一時ファイルを削除
            rm -f "$temp_script"
        else
            log "ERROR: Custom user data validation failed - execution blocked"
        fi
    else
        log "No custom user data provided"
    fi
}

# カスタムユーザーデータの実行
execute_custom_user_data

log "Custom user data processing completed"
%{ endif }

# ==================================================
# 完了処理
# ==================================================

log "EC2 User Data Script completed successfully"

# システム情報をログに出力
log "System Information:"
log "  - AMI ID: $(curl -s http://169.254.169.254/latest/meta-data/ami-id)"
log "  - Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)"
log "  - Instance Type: $(curl -s http://169.254.169.254/latest/meta-data/instance-type)"
log "  - Hostname: $(hostname)"
log "  - Private IP: $(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)"

# 起動完了の通知
log "Instance initialization completed successfully"
