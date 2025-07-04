#!/bin/bash
# ==================================================
# EC2 Auto Scaling Group Module Test Script
# ==================================================
#
# このスクリプトは Auto Scaling Group モジュールの動作確認を行います
#
# 使用方法:
#   ./test_module.sh [validate|plan|apply|destroy]
#
# 前提条件:
#   - AWS CLI が設定済み
#   - Terraform 1.0+ がインストール済み
#   - 起動テンプレートが作成済み
#
# 最新更新: 2024年12月
# ==================================================

set -e

# 色付きログ用の設定
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ログ関数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 現在のディレクトリを保存
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="${SCRIPT_DIR}/terraform"

# コマンドライン引数の処理
COMMAND=${1:-validate}

# 必要なツールのチェック
check_requirements() {
    log_info "必要なツールのチェックを実行中..."

    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI が見つかりません。インストールしてください。"
        exit 1
    fi

    if ! command -v terraform &> /dev/null; then
        log_error "Terraform が見つかりません。インストールしてください。"
        exit 1
    fi

    if ! command -v jq &> /dev/null; then
        log_error "jq が見つかりません。インストールしてください。"
        exit 1
    fi

    log_success "必要なツールが全て利用可能です"
}

# AWS設定の確認
check_aws_config() {
    log_info "AWS設定の確認中..."

    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS認証情報が設定されていません。aws configure を実行してください。"
        exit 1
    fi

    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    AWS_REGION=$(aws configure get region)

    log_success "AWS設定が確認されました"
    log_info "アカウントID: ${ACCOUNT_ID}"
    log_info "リージョン: ${AWS_REGION}"
}

# テスト用の設定ファイルを作成
create_test_config() {
    log_info "テスト用設定ファイルを作成中..."

    if [ ! -f "${TERRAFORM_DIR}/terraform.tfvars" ]; then
        log_warning "terraform.tfvars が見つかりません。テスト用設定を作成します。"

        # デフォルトVPCの確認
        DEFAULT_VPC_ID=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query 'Vpcs[0].VpcId' --output text 2>/dev/null || echo "")

        if [ "$DEFAULT_VPC_ID" == "None" ] || [ -z "$DEFAULT_VPC_ID" ]; then
            log_error "デフォルトVPCが見つかりません。VPCを作成するか、subnet_ids を手動で設定してください。"
            exit 1
        fi

        # 利用可能な起動テンプレートの確認
        LAUNCH_TEMPLATES=$(aws ec2 describe-launch-templates --query 'LaunchTemplates[0].LaunchTemplateId' --output text 2>/dev/null || echo "")

        if [ "$LAUNCH_TEMPLATES" == "None" ] || [ -z "$LAUNCH_TEMPLATES" ]; then
            log_error "起動テンプレートが見つかりません。先に起動テンプレートを作成してください。"
            log_info "起動テンプレートの作成方法については、../launch_template/README.md を参照してください。"
            exit 1
        fi

        cat > "${TERRAFORM_DIR}/terraform.tfvars" << EOF
# ==================================================
# テスト用設定ファイル
# ==================================================
# このファイルは自動生成されました
# 本番環境では適切な値に変更してください

# 基本設定
project = "test-asg"
env     = "dev"
app     = "sample"

# 起動テンプレート
launch_template_id = "${LAUNCH_TEMPLATES}"

# スケーリング設定（テスト用）
min_size         = 0
desired_capacity = 1

# 通知設定（無効）
enable_notifications = false

# 運用管理タグ
owner_team   = "test-team"
owner_email  = "test@example.com"
cost_center  = "test"
billing_code = "TEST-2024"

# 共通タグ
common_tags = {
  Environment = "test"
  Purpose     = "module-testing"
}
EOF

        log_success "テスト用設定ファイルを作成しました: ${TERRAFORM_DIR}/terraform.tfvars"
        log_warning "必要に応じて設定を調整してください。"
    else
        log_info "既存の terraform.tfvars を使用します。"
    fi
}

# Terraform初期化
terraform_init() {
    log_info "Terraform初期化中..."
    cd "${TERRAFORM_DIR}"

    if terraform init; then
        log_success "Terraform初期化が完了しました"
    else
        log_error "Terraform初期化に失敗しました"
        exit 1
    fi
}

# Terraform検証
terraform_validate() {
    log_info "Terraform設定の検証中..."
    cd "${TERRAFORM_DIR}"

    if terraform validate; then
        log_success "Terraform設定の検証が完了しました"
    else
        log_error "Terraform設定の検証に失敗しました"
        exit 1
    fi
}

# Terraform計画
terraform_plan() {
    log_info "Terraform実行計画を作成中..."
    cd "${TERRAFORM_DIR}"

    if terraform plan -out=tfplan; then
        log_success "Terraform実行計画の作成が完了しました"
        log_info "計画ファイル: tfplan"
    else
        log_error "Terraform実行計画の作成に失敗しました"
        exit 1
    fi
}

# Terraform適用
terraform_apply() {
    log_info "Terraform適用を開始します..."
    cd "${TERRAFORM_DIR}"

    if [ -f "tfplan" ]; then
        log_info "既存の計画ファイルを使用します"
        if terraform apply tfplan; then
            log_success "Terraform適用が完了しました"
        else
            log_error "Terraform適用に失敗しました"
            exit 1
        fi
    else
        log_warning "計画ファイルが見つかりません。対話式適用を実行します。"
        if terraform apply; then
            log_success "Terraform適用が完了しました"
        else
            log_error "Terraform適用に失敗しました"
            exit 1
        fi
    fi
}

# Terraform破棄
terraform_destroy() {
    log_warning "Terraform破棄を開始します..."
    cd "${TERRAFORM_DIR}"

    log_warning "この操作により、作成されたリソースが削除されます。"
    read -p "続行しますか？ (y/N): " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if terraform destroy; then
            log_success "Terraform破棄が完了しました"
        else
            log_error "Terraform破棄に失敗しました"
            exit 1
        fi
    else
        log_info "操作をキャンセルしました"
    fi
}

# リソース状態確認
check_resources() {
    log_info "作成されたリソースの状態を確認中..."
    cd "${TERRAFORM_DIR}"

    # Terraformアウトプットの表示
    if terraform output > /dev/null 2>&1; then
        log_info "Terraformアウトプット:"
        terraform output
    fi

    # Auto Scaling Group の状態確認
    ASG_NAME=$(terraform output -raw autoscaling_group_name 2>/dev/null || echo "")
    if [ -n "$ASG_NAME" ]; then
        log_info "Auto Scaling Group の詳細:"
        aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names "$ASG_NAME" --query 'AutoScalingGroups[0].{Name:AutoScalingGroupName,MinSize:MinSize,MaxSize:MaxSize,DesiredCapacity:DesiredCapacity,Instances:length(Instances)}' --output table

        # 最近のスケーリング活動
        log_info "最近のスケーリング活動:"
        aws autoscaling describe-scaling-activities --auto-scaling-group-name "$ASG_NAME" --max-items 3 --query 'Activities[*].{StartTime:StartTime,StatusCode:StatusCode,Description:Description}' --output table
    fi
}

# 使用方法の表示
show_usage() {
    echo "使用方法: $0 [validate|plan|apply|destroy|check]"
    echo ""
    echo "コマンド:"
    echo "  validate  - Terraform設定の検証のみ実行"
    echo "  plan      - Terraform実行計画の作成"
    echo "  apply     - Terraformの適用（リソース作成）"
    echo "  destroy   - Terraformの破棄（リソース削除）"
    echo "  check     - 作成されたリソースの状態確認"
    echo ""
    echo "例:"
    echo "  $0 validate   # 設定の検証"
    echo "  $0 plan       # 実行計画の作成"
    echo "  $0 apply      # リソースの作成"
    echo "  $0 check      # リソース状態の確認"
    echo "  $0 destroy    # リソースの削除"
}

# メイン処理
main() {
    log_info "EC2 Auto Scaling Group モジュールのテストを開始します"
    log_info "コマンド: ${COMMAND}"

    case "$COMMAND" in
        "validate")
            check_requirements
            check_aws_config
            create_test_config
            terraform_init
            terraform_validate
            ;;
        "plan")
            check_requirements
            check_aws_config
            create_test_config
            terraform_init
            terraform_validate
            terraform_plan
            ;;
        "apply")
            check_requirements
            check_aws_config
            create_test_config
            terraform_init
            terraform_validate
            terraform_plan
            terraform_apply
            check_resources
            ;;
        "destroy")
            check_requirements
            check_aws_config
            terraform_init
            terraform_destroy
            ;;
        "check")
            check_requirements
            check_aws_config
            check_resources
            ;;
        "help"|"-h"|"--help")
            show_usage
            ;;
        *)
            log_error "不明なコマンド: ${COMMAND}"
            show_usage
            exit 1
            ;;
    esac

    log_success "テストが完了しました"
}

# スクリプト実行
main "$@"
