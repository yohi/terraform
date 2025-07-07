# ==================================================
# プロジェクト基本設定
# ==================================================

variable "aws_region" {
  description = "AWSリージョン"
  type        = string
  default     = "ap-northeast-1"
}

variable "project_name" {
  description = "プロジェクト名"
  type        = string
  default     = "myproject"
}

variable "environment" {
  description = "環境名（prd, rls, stg, devなど）"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["prd", "rls", "stg", "dev"], var.environment)
    error_message = "environment は prd, rls, stg, dev のいずれかである必要があります。"
  }
}

variable "app" {
  description = "アプリケーション名（空文字列の場合は省略される）"
  type        = string
  default     = ""
}

# ==================================================
# AMI設定
# ==================================================

variable "ami_name_filter" {
  description = "AMI検索用の名前フィルター"
  type        = list(string)
  default     = ["amzn2023-ami-ecs-*"]
}

# ==================================================
# EC2インスタンス設定
# ==================================================

variable "instance_type" {
  description = "EC2インスタンスタイプ"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "EC2キーペア名"
  type        = string
  default     = ""
}

variable "ssh_cidr_blocks" {
  description = "SSH接続を許可するCIDRブロックのリスト（セキュリティのため、明示的に信頼できるIPアドレス範囲を指定してください）"
  type        = list(string)
  default     = []  # セキュリティのため、デフォルトは空リスト。必要に応じて特定のIPアドレス範囲を明示的に指定する
}

variable "associate_public_ip" {
  description = "パブリックIPアドレスを割り当てるかどうか"
  type        = bool
  default     = true
}

variable "iam_instance_profile_name" {
  description = "IAMインスタンスプロファイル名"
  type        = string
  default     = ""
}

# ==================================================
# EBSストレージ設定
# ==================================================

variable "volume_size" {
  description = "EBSボリュームサイズ（GB）"
  type        = number
  default     = 20
}

variable "volume_type" {
  description = "EBSボリュームタイプ"
  type        = string
  default     = "gp3"
}

# ==================================================
# ECS設定
# ==================================================

variable "ecs_cluster_name" {
  description = "ECSクラスター名（空の場合は自動生成: {project}-{env}-ecs）"
  type        = string
  default     = ""
}

# ==================================================
# CloudWatch Agent設定
# ==================================================

variable "cloudwatch_agent_config" {
  description = "CloudWatchエージェントの設定名（空の場合は自動生成: AmazonCloudWatch-Agent_{project}-ecs）"
  type        = string
  default     = ""
}

variable "cloudwatch_agent_config_json" {
  description = "CloudWatchエージェントの設定JSON（Parameter Storeに保存）"
  type        = string
  default     = ""
}

variable "cloudwatch_default_namespace" {
  description = "CloudWatchエージェントのデフォルトネームスペース"
  type        = string
  default     = ""
}

variable "cloudwatch_metrics_collection_interval" {
  description = "CloudWatchメトリクス収集間隔（秒）"
  type        = number
  default     = 60
}

variable "cloudwatch_run_as_user" {
  description = "CloudWatchエージェントの実行ユーザー"
  type        = string
  default     = "cwagent"
}

variable "cloudwatch_cpu_metrics" {
  description = "CloudWatch CPU メトリクス設定"
  type = object({
    measurement                 = list(string)
    metrics_collection_interval = number
    totalcpu                   = bool
  })
  default = {
    measurement = ["cpu_usage_idle", "cpu_usage_iowait", "cpu_usage_user", "cpu_usage_system"]
    metrics_collection_interval = 60
    totalcpu = false
  }
}

variable "cloudwatch_disk_metrics" {
  description = "CloudWatch Disk メトリクス設定"
  type        = list(string)
  default     = ["used_percent", "inodes_free"]
}

variable "cloudwatch_disk_resources" {
  description = "CloudWatch Disk リソース設定"
  type        = list(string)
  default     = ["*"]
}

variable "cloudwatch_diskio_metrics" {
  description = "CloudWatch Disk I/O メトリクス設定"
  type        = list(string)
  default     = ["io_time", "read_bytes", "write_bytes", "reads", "writes"]
}

variable "cloudwatch_mem_metrics" {
  description = "CloudWatch メモリ メトリクス設定"
  type        = list(string)
  default     = ["mem_used_percent"]
}

variable "cloudwatch_enable_statsd" {
  description = "CloudWatch StatsD機能を有効にするかどうか"
  type        = bool
  default     = false
}

variable "cloudwatch_statsd_port" {
  description = "CloudWatch StatsDポート番号"
  type        = number
  default     = 8125
}

variable "create_default_cloudwatch_config" {
  description = "CloudWatch設定がない場合にデフォルト設定を作成するかどうか"
  type        = bool
  default     = true
}

# ==================================================
# Mackerel設定
# ==================================================

variable "mackerel_api_key" {
  description = "MackerelのAPIキー"
  type        = string
  default     = ""
  sensitive   = true
}

variable "mackerel_default_api_key" {
  description = "MackerelのデフォルトAPIキー（mackerel_api_keyが空の場合に使用）"
  type        = string
  default     = ""
  sensitive   = true
}

variable "mackerel_parameter_prefix" {
  description = "MackerelエージェントのParameter Storeパラメータ名プレフィックス（空の場合は自動生成: /{project}/{env}/config/mackerel/）"
  type        = string
  default     = ""
}

variable "mackerel_organization" {
  description = "Mackerelの組織名（Parameter Storeに保存）"
  type        = string
  default     = ""
}

variable "mackerel_display_name" {
  description = "Mackerelエージェントの表示名（空の場合は自動生成: {project}-{env}-{app}）"
  type        = string
  default     = ""
}

variable "mackerel_roles" {
  description = "Mackerelのロール（Parameter Storeに保存、カンマ区切り）"
  type        = string
  default     = ""
}

variable "mackerel_default_roles" {
  description = "Mackerelのデフォルトロール（リスト形式、mackerel_rolesが空の場合に使用）"
  type        = list(string)
  default     = []
}

variable "mackerel_auto_retirement" {
  description = "MackerelのAUTO_RETIREMENT設定（Parameter Storeから取得する場合は空文字列、直接指定する場合は0または1）"
  type        = string
  default     = ""
}

variable "mackerel_agent_config" {
  description = "Mackerelエージェントの追加設定（Parameter Storeに保存、TOML形式）"
  type        = string
  default     = ""
}

variable "mackerel_sysconfig_template" {
  description = "MackerelのSysconfig設定テンプレート（空の場合はデフォルトテンプレートを使用）"
  type        = string
  default     = ""
}

variable "mackerel_enable_sysconfig" {
  description = "MackerelのSysconfig設定を有効にするかどうか"
  type        = bool
  default     = true
}

variable "mackerel_additional_env_vars" {
  description = "Mackerelの追加環境変数（key-value形式）"
  type        = map(string)
  default     = {}
}

variable "create_default_mackerel_config" {
  description = "Mackerel設定がない場合にデフォルト設定を作成するかどうか"
  type        = bool
  default     = true
}

# ==================================================
# その他設定
# ==================================================

variable "ctop_version" {
  description = "ctopのバージョン"
  type        = string
  default     = "0.7.7"
}

variable "custom_user_data" {
  description = "追加で実行するカスタムユーザーデータスクリプト"
  type        = string
  default     = ""
}

# ==================================================
# Parameter Store設定
# ==================================================

variable "create_parameter_store" {
  description = "Parameter Storeのパラメータを作成するかどうか"
  type        = bool
  default     = true
}

variable "parameter_store_kms_key_id" {
  description = "Parameter Store用のKMSキーID（指定しない場合はデフォルトキーを使用）"
  type        = string
  default     = ""
}

# ==================================================
# タグ設定
# ==================================================

variable "common_tags" {
  description = "全リソースに適用する共通タグ"
  type        = map(string)
  default = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }

variable "owner_team" {
  description = "リソースの所有者チーム"
  type        = string
  default     = "devops-team"
}

variable "owner_email" {
  description = "リソースの所有者チームのメールアドレス"
  type        = string
  default     = "devops@example.com"
}

variable "cost_center" {
  description = "コストセンター"
  type        = string
  default     = "engineering"
}

variable "billing_code" {
  description = "請求コード"
  type        = string
  default     = ""
}

variable "data_classification" {
  description = "データ分類レベル (public, internal, confidential, restricted)"
  type        = string
  default     = "internal"

  validation {
    condition     = contains(["public", "internal", "confidential", "restricted"], var.data_classification)
    error_message = "data_classification は 'public', 'internal', 'confidential', 'restricted' のいずれかである必要があります。"
}

variable "backup_required" {
  description = "バックアップが必要かどうか"
  type        = bool
  default     = true
}

variable "monitoring_level" {
  description = "監視レベル (basic, enhanced)"
  type        = string
  default     = "basic"

  validation {
    condition     = contains(["basic", "enhanced"], var.monitoring_level)
    error_message = "monitoring_level は 'basic' または 'enhanced' である必要があります。"
  }
}

variable "schedule" {
  description = "運用スケジュール (24x7, business-hours)"
  type        = string
  default     = "24x7"
}

variable "common_tags" {
  description = "全リソースに適用する共通タグ（追加・上書き用）"
  type        = map(string)
  default     = {}
}
