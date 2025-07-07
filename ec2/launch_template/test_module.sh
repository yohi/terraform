#!/bin/bash
# ==================================================
# EC2 Launch Template Module Test Script
# ==================================================
#
# このスクリプトは Launch Template モジュールの動作確認を行います
#
# 使用方法:
#   ./test_module.sh [validate|plan|apply|destroy|check|cleanup]
#
# 前提条件:
#   - AWS CLI が設定済み
#   - Terraform 1.0+ がインストール済み
#   - 適切なIAM権限が設定済み
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

# テスト用キーペアの作成
create_test_keypair() {
    log_info "テスト用キーペアの確認中..."

    KEY_NAME="test-launch-template-key"

    if aws ec2 describe-key-pairs --key-names "$KEY_NAME" &> /dev/null; then
        log_info "キーペア '$KEY_NAME' が既に存在します。"
    else
        log_info "テスト用キーペア '$KEY_NAME' を作成しています..."
        aws ec2 create-key-pair --key-name "$KEY_NAME" --query 'KeyMaterial' --output text > "${SCRIPT_DIR}/${KEY_NAME}.pem"
        chmod 600 "${SCRIPT_DIR}/${KEY_NAME}.pem"
        log_success "キーペア '$KEY_NAME' を作成しました"
        log_warning "秘密鍵は ${SCRIPT_DIR}/${KEY_NAME}.pem に保存されています"
    fi
}

# テスト用の設定ファイルを作成
create_test_config() {
    log_info "テスト用設定ファイルを作成中..."

    if [ ! -f "${TERRAFORM_DIR}/terraform.tfvars" ]; then
        log_warning "terraform.tfvars が見つかりません。テスト用設定を作成します。"

        # デフォルトVPCの確認
        DEFAULT_VPC_ID=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query 'Vpcs[0].VpcId' --output text 2>/dev/null || echo "")

        if [ "$DEFAULT_VPC_ID" == "None" ] || [ -z "$DEFAULT_VPC_ID" ]; then
            log_error "デフォルトVPCが見つかりません。VPCを作成するか、手動で設定してください。"
            exit 1
        fi

        # テスト用キーペアの作成
        create_test_keypair

        cat > "${TERRAFORM_DIR}/terraform.tfvars" << EOF
# ==================================================
# テスト用設定ファイル
# ==================================================
# このファイルは自動生成されました
# 本番環境では適切な値に変更してください

# 基本設定
project_name = "test-launch-template"
environment  = "dev"
app          = "sample"

# EC2設定
instance_type = "t3.micro"
key_name      = "${KEY_NAME}"
volume_size   = 20

# セキュリティ設定（テスト用）
ssh_cidr_blocks = ["10.0.0.0/16"]  # テスト用：VPC内からのみ

# ECS設定
ecs_cluster_name = "test-launch-template-ecs"

# Mackerel設定（テスト用）
mackerel_api_key = "dummy-api-key-for-test"
mackerel_organization = "test-org"
mackerel_roles = "test,launch-template"

# CloudWatch設定
cloudwatch_default_namespace = "Test/LaunchTemplate"

# 共通タグ
common_tags = {
  Environment = "test"
  Purpose     = "module-testing"
  TestScript  = "launch-template-test"
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

# Parameter Storeパラメータの確認
check_parameter_store() {
    log_info "Parameter Storeパラメータの確認中..."

    # Terraformアウトプットからパラメータ名を取得
    PARAMETER_NAMES=$(terraform output -json parameter_store_names 2>/dev/null | jq -r '.[] // empty' || echo "")

    if [ -n "$PARAMETER_NAMES" ]; then
        log_info "作成されたParameter Storeパラメータ:"
        for param in $PARAMETER_NAMES; do
            if aws ssm get-parameter --name "$param" --query 'Parameter.Name' --output text &> /dev/null; then
                log_success "  ✓ $param"
            else
                log_warning "  ✗ $param (見つかりません)"
            fi
        done
    else
        log_warning "Parameter Storeパラメータが見つかりません"
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

    # Launch Template の状態確認
    LAUNCH_TEMPLATE_ID=$(terraform output -raw launch_template_id 2>/dev/null || echo "")
    if [ -n "$LAUNCH_TEMPLATE_ID" ]; then
        log_info "Launch Template の詳細:"
        aws ec2 describe-launch-templates --launch-template-ids "$LAUNCH_TEMPLATE_ID" --query 'LaunchTemplates[0].{LaunchTemplateId:LaunchTemplateId,LaunchTemplateName:LaunchTemplateName,LatestVersionNumber:LatestVersionNumber,DefaultVersionNumber:DefaultVersionNumber}' --output table

        # Launch Template Version の詳細
        log_info "Launch Template Version の詳細:"
        aws ec2 describe-launch-template-versions --launch-template-id "$LAUNCH_TEMPLATE_ID" --versions '$Latest' --query 'LaunchTemplateVersions[0].LaunchTemplateData.{ImageId:ImageId,InstanceType:InstanceType,KeyName:KeyName,SecurityGroupIds:SecurityGroupIds}' --output table
    fi

    # Security Group の状態確認
    SECURITY_GROUP_ID=$(terraform output -raw security_group_id 2>/dev/null || echo "")
    if [ -n "$SECURITY_GROUP_ID" ]; then
        log_info "Security Group の詳細:"
        aws ec2 describe-security-groups --group-ids "$SECURITY_GROUP_ID" --query 'SecurityGroups[0].{GroupId:GroupId,GroupName:GroupName,Description:Description}' --output table
    fi

    # Parameter Store パラメータの確認
    check_parameter_store

    # 使用されたAMIの詳細
    AMI_ID=$(terraform output -raw ami_id 2>/dev/null || echo "")
    if [ -n "$AMI_ID" ]; then
        log_info "使用されたAMIの詳細:"
        aws ec2 describe-images --image-ids "$AMI_ID" --query 'Images[0].{ImageId:ImageId,Name:Name,CreationDate:CreationDate,Description:Description}' --output table
    fi
}

# クリーンアップ処理
cleanup_resources() {
    log_info "テスト用リソースのクリーンアップを開始します..."

    # テスト用キーペアの削除
    KEY_NAME="test-launch-template-key"
    if aws ec2 describe-key-pairs --key-names "$KEY_NAME" &> /dev/null; then
        log_info "テスト用キーペア '$KEY_NAME' を削除しています..."
        aws ec2 delete-key-pair --key-name "$KEY_NAME"

        # ローカルの秘密鍵ファイルも削除
        if [ -f "${SCRIPT_DIR}/${KEY_NAME}.pem" ]; then
            rm "${SCRIPT_DIR}/${KEY_NAME}.pem"
        fi

        log_success "キーペア '$KEY_NAME' を削除しました"
    fi

    # terraform.tfvarsの削除（テスト用ファイルの場合）
    if [ -f "${TERRAFORM_DIR}/terraform.tfvars" ]; then
        if grep -q "# このファイルは自動生成されました" "${TERRAFORM_DIR}/terraform.tfvars"; then
            log_info "自動生成されたテスト用設定ファイルを削除しています..."
            rm "${TERRAFORM_DIR}/terraform.tfvars"
            log_success "テスト用設定ファイルを削除しました"
        fi
    fi

    # Terraform計画ファイルの削除
    if [ -f "${TERRAFORM_DIR}/tfplan" ]; then
        rm "${TERRAFORM_DIR}/tfplan"
        log_success "Terraform計画ファイルを削除しました"
    fi

    log_success "クリーンアップが完了しました"
}

# 使用方法の表示
show_usage() {
    echo "使用方法: $0 [validate|plan|apply|destroy|check|cleanup]"
    echo ""
    echo "コマンド:"
    echo "  validate  - Terraform設定の検証のみ実行"
    echo "  plan      - Terraform実行計画の作成"
    echo "  apply     - Terraformの適用（リソース作成）"
    echo "  destroy   - Terraformの破棄（リソース削除）"
    echo "  check     - 作成されたリソースの状態確認"
    echo "  cleanup   - テスト用リソースのクリーンアップ"
    echo ""
    echo "例:"
    echo "  $0 validate   # 設定の検証"
    echo "  $0 plan       # 実行計画の作成"
    echo "  $0 apply      # リソースの作成"
    echo "  $0 check      # リソース状態の確認"
    echo "  $0 destroy    # リソースの削除"
    echo "  $0 cleanup    # テスト用リソースのクリーンアップ"
}

# メイン処理
main() {
    log_info "EC2 Launch Template モジュールのテストを開始します"
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
        "cleanup")
            cleanup_resources
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
