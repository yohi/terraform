#!/bin/bash
# ==================================================
# EC2 Integration Test Script
# ==================================================
#
# このスクリプトは Launch Template と Auto Scaling Group の
# 統合テストを実行します
#
# 使用方法:
#   ./run_integration_tests.sh [full|validate|plan|apply|destroy|cleanup]
#
# 前提条件:
#   - AWS CLI が設定済み
#   - Terraform 1.0+ がインストール済み
#   - 適切なIAM権限が設定済み
#
# テストの流れ:
#   1. Launch Template の作成
#   2. Launch Template ID の取得
#   3. Auto Scaling Group の作成（Launch Template ID を使用）
#   4. 統合テストの実行
#
# 最新更新: 2024年12月
# ==================================================

set -e

# 色付きログ用の設定
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
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

log_integration() {
    echo -e "${PURPLE}[INTEGRATION]${NC} $1"
}

# 現在のディレクトリを保存
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAUNCH_TEMPLATE_DIR="${SCRIPT_DIR}/launch_template"
AUTO_SCALING_GROUP_DIR="${SCRIPT_DIR}/auto_scaling_group"

# コマンドライン引数の処理
COMMAND=${1:-full}

# 統合テスト用の設定
INTEGRATION_PROJECT="ec2-integration-test"
INTEGRATION_ENV="dev"
INTEGRATION_APP="webapp"

# 必要なツールのチェック
check_requirements() {
    log_info "統合テストの前提条件をチェック中..."

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

    # テストスクリプトの存在確認
    if [ ! -f "${LAUNCH_TEMPLATE_DIR}/test_module.sh" ]; then
        log_error "Launch Template テストスクリプトが見つかりません。"
        exit 1
    fi

    if [ ! -f "${AUTO_SCALING_GROUP_DIR}/test_module.sh" ]; then
        log_error "Auto Scaling Group テストスクリプトが見つかりません。"
        exit 1
    fi

    log_success "前提条件の確認が完了しました"
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

# Launch Template の統合テスト用設定を作成
create_launch_template_config() {
    log_integration "Launch Template の統合テスト用設定を作成中..."

    local config_file="${LAUNCH_TEMPLATE_DIR}/terraform/terraform.tfvars"

    cat > "$config_file" << EOF
# ==================================================
# 統合テスト用設定ファイル - Launch Template
# ==================================================
# このファイルは統合テスト用に自動生成されました

# 基本設定
project_name = "${INTEGRATION_PROJECT}"
environment  = "${INTEGRATION_ENV}"
app          = "${INTEGRATION_APP}"

# EC2設定
instance_type = "t3.micro"
key_name      = "integration-test-key"
volume_size   = 20

# セキュリティ設定
ssh_cidr_blocks = ["10.0.0.0/16"]

# ECS設定
ecs_cluster_name = "${INTEGRATION_PROJECT}-${INTEGRATION_ENV}-ecs"

# Mackerel設定
mackerel_api_key = "dummy-api-key-for-integration-test"
mackerel_organization = "integration-test-org"
mackerel_roles = "integration,test,launch-template"

# CloudWatch設定
cloudwatch_default_namespace = "IntegrationTest/LaunchTemplate"

# 共通タグ
common_tags = {
  Environment = "${INTEGRATION_ENV}"
  Project     = "${INTEGRATION_PROJECT}"
  Purpose     = "integration-testing"
  TestType    = "launch-template"
}
EOF

    log_success "Launch Template の統合テスト用設定を作成しました"
}

# Auto Scaling Group の統合テスト用設定を作成
create_auto_scaling_group_config() {
    log_integration "Auto Scaling Group の統合テスト用設定を作成中..."

    local launch_template_id="$1"
    local config_file="${AUTO_SCALING_GROUP_DIR}/terraform/terraform.tfvars"

    cat > "$config_file" << EOF
# ==================================================
# 統合テスト用設定ファイル - Auto Scaling Group
# ==================================================
# このファイルは統合テスト用に自動生成されました

# 基本設定
project_name = "${INTEGRATION_PROJECT}"
environment  = "${INTEGRATION_ENV}"
app          = "${INTEGRATION_APP}"

# 起動テンプレート（統合テストで作成されたもの）
launch_template_id = "${launch_template_id}"

# スケーリング設定（統合テスト用）
min_size         = 0
desired_capacity = 1

# 通知設定（無効）
enable_notifications = false

# 運用管理タグ
owner_team   = "integration-test-team"
owner_email  = "integration-test@example.com"
cost_center  = "test"
billing_code = "INTEGRATION-TEST-2024"

# 共通タグ
common_tags = {
  Environment = "${INTEGRATION_ENV}"
  Project     = "${INTEGRATION_PROJECT}"
  Purpose     = "integration-testing"
  TestType    = "auto-scaling-group"
}
EOF

    log_success "Auto Scaling Group の統合テスト用設定を作成しました"
}

# 統合テスト用キーペアの作成
create_integration_keypair() {
    log_integration "統合テスト用キーペアの確認中..."

    local key_name="integration-test-key"

    if aws ec2 describe-key-pairs --key-names "$key_name" &> /dev/null; then
        log_info "キーペア '$key_name' が既に存在します。"
    else
        log_integration "統合テスト用キーペア '$key_name' を作成しています..."
        aws ec2 create-key-pair --key-name "$key_name" --query 'KeyMaterial' --output text > "${SCRIPT_DIR}/${key_name}.pem"
        chmod 600 "${SCRIPT_DIR}/${key_name}.pem"
        log_success "キーペア '$key_name' を作成しました"
    fi
}

# Launch Template のテストを実行
run_launch_template_test() {
    local action="$1"
    log_integration "Launch Template のテストを実行中: $action"

    cd "${LAUNCH_TEMPLATE_DIR}"

    case "$action" in
        "validate"|"plan"|"apply"|"destroy"|"check")
            if ./test_module.sh "$action"; then
                log_success "Launch Template テスト ($action) が正常に完了しました"
            else
                log_error "Launch Template テスト ($action) が失敗しました"
                return 1
            fi
            ;;
        *)
            log_error "サポートされていないアクション: $action"
            return 1
            ;;
    esac
}

# Auto Scaling Group のテストを実行
run_auto_scaling_group_test() {
    local action="$1"
    log_integration "Auto Scaling Group のテストを実行中: $action"

    cd "${AUTO_SCALING_GROUP_DIR}"

    case "$action" in
        "validate"|"plan"|"apply"|"destroy"|"check")
            if ./test_module.sh "$action"; then
                log_success "Auto Scaling Group テスト ($action) が正常に完了しました"
            else
                log_error "Auto Scaling Group テスト ($action) が失敗しました"
                return 1
            fi
            ;;
        *)
            log_error "サポートされていないアクション: $action"
            return 1
            ;;
    esac
}

# Launch Template ID の取得
get_launch_template_id() {
    log_integration "Launch Template ID を取得中..."

    cd "${LAUNCH_TEMPLATE_DIR}/terraform"

    local launch_template_id
    if launch_template_id=$(terraform output -raw launch_template_id 2>/dev/null); then
        log_success "Launch Template ID を取得しました: $launch_template_id"
        echo "$launch_template_id"
    else
        log_error "Launch Template ID の取得に失敗しました"
        return 1
    fi
}

# 統合テストの検証
run_integration_validation() {
    log_integration "統合テストの検証を実行中..."

    # Launch Template の存在確認
    local launch_template_id
    if launch_template_id=$(get_launch_template_id); then
        log_success "Launch Template が正常に作成されています: $launch_template_id"
    else
        log_error "Launch Template が見つかりません"
        return 1
    fi

    # Auto Scaling Group の存在確認
    cd "${AUTO_SCALING_GROUP_DIR}/terraform"

    local asg_name
    if asg_name=$(terraform output -raw autoscaling_group_name 2>/dev/null); then
        log_success "Auto Scaling Group が正常に作成されています: $asg_name"

        # ASG の Launch Template ID 確認
        local asg_launch_template_id
        if asg_launch_template_id=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names "$asg_name" --query 'AutoScalingGroups[0].LaunchTemplate.LaunchTemplateId' --output text); then
            if [ "$asg_launch_template_id" = "$launch_template_id" ]; then
                log_success "Auto Scaling Group が正しいLaunch Template を使用しています"
            else
                log_error "Auto Scaling Group が異なるLaunch Template を使用しています"
                return 1
            fi
        else
            log_error "Auto Scaling Group のLaunch Template ID が取得できませんでした"
            return 1
        fi
    else
        log_error "Auto Scaling Group が見つかりません"
        return 1
    fi

    log_success "統合テストの検証が完了しました"
}

# 統合テストのクリーンアップ
cleanup_integration_test() {
    log_integration "統合テストのクリーンアップを開始します..."

    # キーペアの削除
    local key_name="integration-test-key"
    if aws ec2 describe-key-pairs --key-names "$key_name" &> /dev/null; then
        log_integration "統合テスト用キーペア '$key_name' を削除しています..."
        aws ec2 delete-key-pair --key-name "$key_name"

        # ローカルの秘密鍵ファイルも削除
        if [ -f "${SCRIPT_DIR}/${key_name}.pem" ]; then
            rm "${SCRIPT_DIR}/${key_name}.pem"
        fi

        log_success "キーペア '$key_name' を削除しました"
    fi

    # 設定ファイルの削除
    for config_file in "${LAUNCH_TEMPLATE_DIR}/terraform/terraform.tfvars" "${AUTO_SCALING_GROUP_DIR}/terraform/terraform.tfvars"; do
        if [ -f "$config_file" ]; then
            if grep -q "# このファイルは統合テスト用に自動生成されました" "$config_file"; then
                rm "$config_file"
                log_success "統合テスト用設定ファイルを削除しました: $config_file"
            fi
        fi
    done

    # Terraform計画ファイルの削除
    for plan_file in "${LAUNCH_TEMPLATE_DIR}/terraform/tfplan" "${AUTO_SCALING_GROUP_DIR}/terraform/tfplan"; do
        if [ -f "$plan_file" ]; then
            rm "$plan_file"
            log_success "Terraform計画ファイルを削除しました: $plan_file"
        fi
    done

    log_success "統合テストのクリーンアップが完了しました"
}

# 使用方法の表示
show_usage() {
    echo "使用方法: $0 [full|validate|plan|apply|destroy|cleanup]"
    echo ""
    echo "コマンド:"
    echo "  full      - 完全な統合テストを実行（作成→検証→削除）"
    echo "  validate  - 両方のモジュールの設定検証"
    echo "  plan      - 両方のモジュールの実行計画作成"
    echo "  apply     - 両方のモジュールの適用（リソース作成）"
    echo "  destroy   - 両方のモジュールの破棄（リソース削除）"
    echo "  cleanup   - 統合テスト用リソースのクリーンアップ"
    echo ""
    echo "実行順序："
    echo "  作成時: Launch Template → Auto Scaling Group"
    echo "  削除時: Auto Scaling Group → Launch Template"
    echo ""
    echo "例:"
    echo "  $0 full       # 完全な統合テスト"
    echo "  $0 validate   # 設定の検証"
    echo "  $0 apply      # リソースの作成"
    echo "  $0 destroy    # リソースの削除"
    echo "  $0 cleanup    # クリーンアップ"
}

# メイン処理
main() {
    log_integration "EC2 統合テストを開始します"
    log_integration "コマンド: ${COMMAND}"

    case "$COMMAND" in
        "full")
            check_requirements
            check_aws_config
            create_integration_keypair
            create_launch_template_config

            # 順次実行: Launch Template → Auto Scaling Group
            log_integration "=== Phase 1: Launch Template の作成 ==="
            run_launch_template_test "apply"

            # Launch Template ID を取得してAuto Scaling Group の設定を作成
            launch_template_id=$(get_launch_template_id)
            create_auto_scaling_group_config "$launch_template_id"

            log_integration "=== Phase 2: Auto Scaling Group の作成 ==="
            run_auto_scaling_group_test "apply"

            log_integration "=== Phase 3: 統合テストの検証 ==="
            run_integration_validation

            log_integration "=== Phase 4: リソースの削除 ==="
            # 逆順で削除: Auto Scaling Group → Launch Template
            run_auto_scaling_group_test "destroy"
            run_launch_template_test "destroy"

            log_integration "=== Phase 5: クリーンアップ ==="
            cleanup_integration_test

            log_success "統合テストが正常に完了しました"
            ;;

        "validate")
            check_requirements
            check_aws_config
            create_integration_keypair
            create_launch_template_config

            # 並行実行が可能
            log_integration "=== Launch Template の検証 ==="
            run_launch_template_test "validate"

            # ダミーのLaunch Template IDでAuto Scaling Group の設定を作成
            create_auto_scaling_group_config "lt-dummy-for-validation"

            log_integration "=== Auto Scaling Group の検証 ==="
            run_auto_scaling_group_test "validate"

            cleanup_integration_test
            ;;

        "plan")
            check_requirements
            check_aws_config
            create_integration_keypair
            create_launch_template_config

            # 順次実行が必要
            log_integration "=== Launch Template の計画 ==="
            run_launch_template_test "plan"

            # ダミーのLaunch Template IDでAuto Scaling Group の設定を作成
            create_auto_scaling_group_config "lt-dummy-for-plan"

            log_integration "=== Auto Scaling Group の計画 ==="
            run_auto_scaling_group_test "plan"

            cleanup_integration_test
            ;;

        "apply")
            check_requirements
            check_aws_config
            create_integration_keypair
            create_launch_template_config

            # 順次実行: Launch Template → Auto Scaling Group
            log_integration "=== Launch Template の適用 ==="
            run_launch_template_test "apply"

            launch_template_id=$(get_launch_template_id)
            create_auto_scaling_group_config "$launch_template_id"

            log_integration "=== Auto Scaling Group の適用 ==="
            run_auto_scaling_group_test "apply"

            log_integration "=== 統合テストの検証 ==="
            run_integration_validation
            ;;

        "destroy")
            check_requirements
            check_aws_config

            # 逆順で削除: Auto Scaling Group → Launch Template
            log_integration "=== Auto Scaling Group の削除 ==="
            run_auto_scaling_group_test "destroy"

            log_integration "=== Launch Template の削除 ==="
            run_launch_template_test "destroy"

            cleanup_integration_test
            ;;

        "cleanup")
            cleanup_integration_test
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

    log_success "統合テストが完了しました"
}

# スクリプト実行
main "$@"
