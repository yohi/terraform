#!/bin/bash
# ==================================================
# EC2 Test Suite Manager
# ==================================================
#
# このスクリプトは EC2 モジュールの包括的なテストスイートを管理します
#
# 使用方法:
#   ./test_suite.sh [SCENARIO] [OPTIONS]
#
# テストシナリオ:
#   list         - 利用可能なテストシナリオの一覧表示
#   quick        - 高速テスト（設定検証のみ）
#   basic        - 基本テスト（各モジュールの単体テスト）
#   integration  - 統合テスト（モジュール間の連携テスト）
#   full         - 完全テスト（統合テスト + 削除まで）
#   security     - セキュリティテスト（設定の安全性確認）
#   performance  - パフォーマンステスト（リソース効率性確認）
#   cleanup      - テストリソースのクリーンアップ
#
# オプション:
#   --dry-run    - 実際のAWSリソースを作成せずに実行
#   --verbose    - 詳細なログ出力
#   --parallel   - 並行実行可能なテストを並行実行
#   --region     - AWSリージョンを指定
#   --profile    - AWSプロファイルを指定
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
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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

log_suite() {
    echo -e "${CYAN}[SUITE]${NC} $1"
}

log_scenario() {
    echo -e "${PURPLE}[SCENARIO]${NC} $1"
}

# 現在のディレクトリを保存
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAUNCH_TEMPLATE_DIR="${SCRIPT_DIR}/launch_template"
AUTO_SCALING_GROUP_DIR="${SCRIPT_DIR}/auto_scaling_group"

# デフォルト値
SCENARIO=""
DRY_RUN=false
VERBOSE=false
PARALLEL=false
AWS_REGION=""
AWS_PROFILE=""
START_TIME=$(date +%s)

# テスト結果を保存する変数
declare -A TEST_RESULTS
TEST_COUNT=0
SUCCESS_COUNT=0
FAILURE_COUNT=0

# コマンドライン引数の処理
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --parallel)
            PARALLEL=true
            shift
            ;;
        --region)
            AWS_REGION="$2"
            shift 2
            ;;
        --profile)
            AWS_PROFILE="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            if [ -z "$SCENARIO" ]; then
                SCENARIO="$1"
            else
                log_error "不明なオプション: $1"
                show_usage
                exit 1
            fi
            shift
            ;;
    esac
done

# デフォルトシナリオ
if [ -z "$SCENARIO" ]; then
    SCENARIO="list"
fi

# 詳細ログ用の関数
log_verbose() {
    if [ "$VERBOSE" = true ]; then
        log_info "🔍 $1"
    fi
}

# テスト結果の記録
record_test_result() {
    local test_name="$1"
    local result="$2"
    local duration="${3:-0}"

    TEST_RESULTS["$test_name"]="$result:$duration"
    TEST_COUNT=$((TEST_COUNT + 1))

    if [ "$result" = "SUCCESS" ]; then
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        log_success "✅ $test_name (${duration}s)"
    else
        FAILURE_COUNT=$((FAILURE_COUNT + 1))
        log_error "❌ $test_name (${duration}s)"
    fi
}

# AWS設定の確認
check_aws_config() {
    log_verbose "AWS設定の確認中..."

    # AWSプロファイルの設定
    if [ -n "$AWS_PROFILE" ]; then
        export AWS_PROFILE="$AWS_PROFILE"
        log_verbose "AWSプロファイル: $AWS_PROFILE"
    fi

    # AWSリージョンの設定
    if [ -n "$AWS_REGION" ]; then
        export AWS_DEFAULT_REGION="$AWS_REGION"
        log_verbose "AWSリージョン: $AWS_REGION"
    fi

    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS認証情報が設定されていません"
        return 1
    fi

    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    CURRENT_REGION=$(aws configure get region)

    log_verbose "アカウントID: $ACCOUNT_ID"
    log_verbose "リージョン: $CURRENT_REGION"

    return 0
}

# 前提条件のチェック
check_prerequisites() {
    log_suite "前提条件をチェック中..."
    local start_time=$(date +%s)

    # 必要なツールのチェック
    local missing_tools=()

    if ! command -v aws &> /dev/null; then
        missing_tools+=("aws")
    fi

    if ! command -v terraform &> /dev/null; then
        missing_tools+=("terraform")
    fi

    if ! command -v jq &> /dev/null; then
        missing_tools+=("jq")
    fi

    if [ ${#missing_tools[@]} -gt 0 ]; then
        log_error "以下のツールが見つかりません: ${missing_tools[*]}"
        record_test_result "prerequisites" "FAILURE" $(($(date +%s) - start_time))
        return 1
    fi

    # AWS設定の確認
    if ! check_aws_config; then
        record_test_result "prerequisites" "FAILURE" $(($(date +%s) - start_time))
        return 1
    fi

    # テストスクリプトの存在確認
    local missing_scripts=()

    if [ ! -f "${LAUNCH_TEMPLATE_DIR}/test_module.sh" ]; then
        missing_scripts+=("launch_template/test_module.sh")
    fi

    if [ ! -f "${AUTO_SCALING_GROUP_DIR}/test_module.sh" ]; then
        missing_scripts+=("auto_scaling_group/test_module.sh")
    fi

    if [ ! -f "${SCRIPT_DIR}/run_integration_tests.sh" ]; then
        missing_scripts+=("run_integration_tests.sh")
    fi

    if [ ${#missing_scripts[@]} -gt 0 ]; then
        log_error "以下のテストスクリプトが見つかりません: ${missing_scripts[*]}"
        record_test_result "prerequisites" "FAILURE" $(($(date +%s) - start_time))
        return 1
    fi

    record_test_result "prerequisites" "SUCCESS" $(($(date +%s) - start_time))
    return 0
}

# 単体テストの実行
run_unit_test() {
    local module_name="$1"
    local test_action="$2"
    local module_dir="${SCRIPT_DIR}/${module_name}"

    log_verbose "${module_name}の単体テスト（$test_action）を実行中..."
    local start_time=$(date +%s)

    if [ "$DRY_RUN" = true ]; then
        log_warning "🧪 DRY-RUN: ${module_name} ${test_action}"
        record_test_result "${module_name}_${test_action}" "SUCCESS" $(($(date +%s) - start_time))
        return 0
    fi

    cd "$module_dir"

    if ./test_module.sh "$test_action" &> /tmp/test_${module_name}_${test_action}.log; then
        record_test_result "${module_name}_${test_action}" "SUCCESS" $(($(date +%s) - start_time))
        return 0
    else
        log_error "${module_name}の単体テスト（$test_action）が失敗しました"
        if [ "$VERBOSE" = true ]; then
            cat /tmp/test_${module_name}_${test_action}.log
        fi
        record_test_result "${module_name}_${test_action}" "FAILURE" $(($(date +%s) - start_time))
        return 1
    fi
}

# 統合テストの実行
run_integration_test() {
    local test_action="$1"

    log_verbose "統合テスト（$test_action）を実行中..."
    local start_time=$(date +%s)

    if [ "$DRY_RUN" = true ]; then
        log_warning "🧪 DRY-RUN: integration $test_action"
        record_test_result "integration_${test_action}" "SUCCESS" $(($(date +%s) - start_time))
        return 0
    fi

    cd "$SCRIPT_DIR"

    if ./run_integration_tests.sh "$test_action" &> /tmp/test_integration_${test_action}.log; then
        record_test_result "integration_${test_action}" "SUCCESS" $(($(date +%s) - start_time))
        return 0
    else
        log_error "統合テスト（$test_action）が失敗しました"
        if [ "$VERBOSE" = true ]; then
            cat /tmp/test_integration_${test_action}.log
        fi
        record_test_result "integration_${test_action}" "FAILURE" $(($(date +%s) - start_time))
        return 1
    fi
}

# セキュリティテストの実行
run_security_test() {
    log_scenario "セキュリティテストを実行中..."
    local start_time=$(date +%s)

    if [ "$DRY_RUN" = true ]; then
        log_warning "🧪 DRY-RUN: security test"
        record_test_result "security_test" "SUCCESS" $(($(date +%s) - start_time))
        return 0
    fi

    # セキュリティ設定の確認
    local security_issues=()

    # Launch Template のセキュリティ設定確認
    if [ -f "${LAUNCH_TEMPLATE_DIR}/terraform/terraform.tfvars" ]; then
        # SSH接続の設定確認
        if grep -q "ssh_cidr_blocks.*0.0.0.0/0" "${LAUNCH_TEMPLATE_DIR}/terraform/terraform.tfvars"; then
            security_issues+=("Launch Template: SSH接続が全てのIPアドレスに開放されています")
        fi

        # 暗号化設定の確認
        if ! grep -q "encrypted.*=.*true" "${LAUNCH_TEMPLATE_DIR}/terraform/main.tf"; then
            security_issues+=("Launch Template: EBSボリュームが暗号化されていない可能性があります")
        fi
    fi

    # Auto Scaling Group のセキュリティ設定確認
    if [ -f "${AUTO_SCALING_GROUP_DIR}/terraform/terraform.tfvars" ]; then
        # 通知設定の確認
        if grep -q "enable_notifications.*=.*true" "${AUTO_SCALING_GROUP_DIR}/terraform/terraform.tfvars"; then
            if ! grep -q "sns_kms_key_id" "${AUTO_SCALING_GROUP_DIR}/terraform/terraform.tfvars"; then
                security_issues+=("Auto Scaling Group: SNS通知が暗号化されていない可能性があります")
            fi
        fi
    fi

    if [ ${#security_issues[@]} -gt 0 ]; then
        log_warning "セキュリティ上の問題が発見されました:"
        for issue in "${security_issues[@]}"; do
            log_warning "  - $issue"
        done
        record_test_result "security_test" "WARNING" $(($(date +%s) - start_time))
    else
        record_test_result "security_test" "SUCCESS" $(($(date +%s) - start_time))
    fi

    return 0
}

# パフォーマンステストの実行
run_performance_test() {
    log_scenario "パフォーマンステストを実行中..."
    local start_time=$(date +%s)

    if [ "$DRY_RUN" = true ]; then
        log_warning "🧪 DRY-RUN: performance test"
        record_test_result "performance_test" "SUCCESS" $(($(date +%s) - start_time))
        return 0
    fi

    # 設定の効率性確認
    local performance_issues=()

    # Launch Template の設定確認
    if [ -f "${LAUNCH_TEMPLATE_DIR}/terraform/terraform.tfvars" ]; then
        # インスタンスタイプの確認
        if grep -q "instance_type.*=.*\"t3.nano\"" "${LAUNCH_TEMPLATE_DIR}/terraform/terraform.tfvars"; then
            performance_issues+=("Launch Template: t3.nanoは本番環境では性能不足の可能性があります")
        fi

        # ボリュームタイプの確認
        if grep -q "volume_type.*=.*\"gp2\"" "${LAUNCH_TEMPLATE_DIR}/terraform/terraform.tfvars"; then
            performance_issues+=("Launch Template: gp3の方が性能とコストの面で優れています")
        fi
    fi

    # Auto Scaling Group の設定確認
    if [ -f "${AUTO_SCALING_GROUP_DIR}/terraform/terraform.tfvars" ]; then
        # スケーリング設定の確認
        if grep -q "desired_capacity.*=.*1" "${AUTO_SCALING_GROUP_DIR}/terraform/terraform.tfvars"; then
            performance_issues+=("Auto Scaling Group: 単一インスタンスでは冗長性が不十分です")
        fi

        # ヘルスチェック設定の確認
        if grep -q "health_check_grace_period.*=.*60" "${AUTO_SCALING_GROUP_DIR}/terraform/terraform.tfvars"; then
            performance_issues+=("Auto Scaling Group: ヘルスチェック猶予期間が短すぎる可能性があります")
        fi
    fi

    if [ ${#performance_issues[@]} -gt 0 ]; then
        log_warning "パフォーマンス上の改善点が発見されました:"
        for issue in "${performance_issues[@]}"; do
            log_warning "  - $issue"
        done
        record_test_result "performance_test" "WARNING" $(($(date +%s) - start_time))
    else
        record_test_result "performance_test" "SUCCESS" $(($(date +%s) - start_time))
    fi

    return 0
}

# テストシナリオの実行
run_scenario() {
    local scenario="$1"

    case "$scenario" in
        "list")
            show_scenario_list
            ;;
        "quick")
            run_quick_test
            ;;
        "basic")
            run_basic_test
            ;;
        "integration")
            run_integration_test_scenario
            ;;
        "full")
            run_full_test
            ;;
        "security")
            run_security_test
            ;;
        "performance")
            run_performance_test
            ;;
        "cleanup")
            run_cleanup_test
            ;;
        *)
            log_error "不明なシナリオ: $scenario"
            show_usage
            exit 1
            ;;
    esac
}

# シナリオ一覧の表示
show_scenario_list() {
    log_suite "利用可能なテストシナリオ:"
    echo ""
    echo "🚀 QUICK TEST (約1分)"
    echo "   - 設定ファイルの検証のみ"
    echo "   - AWSリソースは作成されません"
    echo "   - CI/CDパイプラインでの事前確認に最適"
    echo ""
    echo "🔧 BASIC TEST (約5分)"
    echo "   - 各モジュールの単体テスト"
    echo "   - 設定検証 + 実行計画作成"
    echo "   - AWSリソースは作成されません"
    echo ""
    echo "🔗 INTEGRATION TEST (約10分)"
    echo "   - モジュール間の統合テスト"
    echo "   - 実際のAWSリソースを作成・テスト・削除"
    echo "   - 費用が発生します（約$1-2）"
    echo ""
    echo "🌟 FULL TEST (約15分)"
    echo "   - 完全な統合テスト"
    echo "   - セキュリティ + パフォーマンステスト込み"
    echo "   - 実際のAWSリソースを作成・テスト・削除"
    echo "   - 費用が発生します（約$1-2）"
    echo ""
    echo "🔒 SECURITY TEST (約2分)"
    echo "   - セキュリティ設定の確認"
    echo "   - 設定ファイルの安全性チェック"
    echo "   - AWSリソースは作成されません"
    echo ""
    echo "⚡ PERFORMANCE TEST (約2分)"
    echo "   - パフォーマンス設定の確認"
    echo "   - 設定ファイルの効率性チェック"
    echo "   - AWSリソースは作成されません"
    echo ""
    echo "🧹 CLEANUP TEST (約3分)"
    echo "   - テスト用リソースのクリーンアップ"
    echo "   - 残存リソースの確認と削除"
    echo ""
}

# クイックテスト
run_quick_test() {
    log_scenario "クイックテストを実行中..."

    check_prerequisites || return 1

    if [ "$PARALLEL" = true ]; then
        log_verbose "並行実行でクイックテストを実行中..."
        run_unit_test "launch_template" "validate" &
        run_unit_test "auto_scaling_group" "validate" &
        wait
    else
        run_unit_test "launch_template" "validate" || return 1
        run_unit_test "auto_scaling_group" "validate" || return 1
    fi

    log_success "クイックテストが完了しました"
}

# 基本テスト
run_basic_test() {
    log_scenario "基本テストを実行中..."

    check_prerequisites || return 1

    if [ "$PARALLEL" = true ]; then
        log_verbose "並行実行で基本テストを実行中..."
        (run_unit_test "launch_template" "validate" && run_unit_test "launch_template" "plan") &
        (run_unit_test "auto_scaling_group" "validate" && run_unit_test "auto_scaling_group" "plan") &
        wait
    else
        run_unit_test "launch_template" "validate" || return 1
        run_unit_test "launch_template" "plan" || return 1
        run_unit_test "auto_scaling_group" "validate" || return 1
        run_unit_test "auto_scaling_group" "plan" || return 1
    fi

    log_success "基本テストが完了しました"
}

# 統合テストシナリオ
run_integration_test_scenario() {
    log_scenario "統合テストシナリオを実行中..."

    check_prerequisites || return 1
    run_integration_test "full" || return 1

    log_success "統合テストシナリオが完了しました"
}

# 完全テスト
run_full_test() {
    log_scenario "完全テストを実行中..."

    check_prerequisites || return 1
    run_integration_test "full" || return 1
    run_security_test || return 1
    run_performance_test || return 1

    log_success "完全テストが完了しました"
}

# クリーンアップテスト
run_cleanup_test() {
    log_scenario "クリーンアップテストを実行中..."
    local start_time=$(date +%s)

    check_prerequisites || return 1

    if [ "$DRY_RUN" = true ]; then
        log_warning "🧪 DRY-RUN: cleanup test"
        record_test_result "cleanup_test" "SUCCESS" $(($(date +%s) - start_time))
        return 0
    fi

    # 統合テストのクリーンアップ
    run_integration_test "cleanup" || return 1

    # 各モジュールのクリーンアップ
    run_unit_test "launch_template" "cleanup" || return 1
    run_unit_test "auto_scaling_group" "cleanup" || return 1

    record_test_result "cleanup_test" "SUCCESS" $(($(date +%s) - start_time))
    log_success "クリーンアップテストが完了しました"
}

# テスト結果の表示
show_test_results() {
    local end_time=$(date +%s)
    local duration=$((end_time - START_TIME))

    echo ""
    log_suite "テスト結果サマリー"
    echo "=========================================="
    echo "🕐 テスト実行時間: ${duration}秒"
    echo "📊 テスト総数: ${TEST_COUNT}"
    echo "✅ 成功: ${SUCCESS_COUNT}"
    echo "❌ 失敗: ${FAILURE_COUNT}"
    echo "⚠️  警告: $((TEST_COUNT - SUCCESS_COUNT - FAILURE_COUNT))"
    echo "=========================================="

    if [ "$VERBOSE" = true ]; then
        echo ""
        log_suite "詳細結果:"
        for test_name in "${!TEST_RESULTS[@]}"; do
            IFS=':' read -r result duration <<< "${TEST_RESULTS[$test_name]}"
            case "$result" in
                "SUCCESS")
                    echo "  ✅ $test_name (${duration}s)"
                    ;;
                "FAILURE")
                    echo "  ❌ $test_name (${duration}s)"
                    ;;
                "WARNING")
                    echo "  ⚠️  $test_name (${duration}s)"
                    ;;
            esac
        done
    fi

    echo ""
    if [ $FAILURE_COUNT -eq 0 ]; then
        log_success "🎉 全てのテストが正常に完了しました！"

        # 成功率の計算
        local success_rate=$((SUCCESS_COUNT * 100 / TEST_COUNT))
        echo "   成功率: ${success_rate}%"

        # 推定コスト情報
        if [ "$SCENARIO" = "integration" ] || [ "$SCENARIO" = "full" ]; then
            echo "   推定コスト: $1-2 (テストリソースは削除済み)"
        else
            echo "   推定コスト: $0 (リソース作成なし)"
        fi
    else
        log_error "💥 一部のテストが失敗しました"
        echo "   失敗したテストのログを確認してください"
        exit 1
    fi
}

# 使用方法の表示
show_usage() {
    echo "使用方法: $0 [SCENARIO] [OPTIONS]"
    echo ""
    echo "テストシナリオ:"
    echo "  list         - 利用可能なテストシナリオの一覧表示"
    echo "  quick        - 高速テスト（設定検証のみ、約1分）"
    echo "  basic        - 基本テスト（各モジュールの単体テスト、約5分）"
    echo "  integration  - 統合テスト（モジュール間の連携テスト、約10分）"
    echo "  full         - 完全テスト（統合テスト + セキュリティ + パフォーマンス、約15分）"
    echo "  security     - セキュリティテスト（設定の安全性確認、約2分）"
    echo "  performance  - パフォーマンステスト（リソース効率性確認、約2分）"
    echo "  cleanup      - テストリソースのクリーンアップ（約3分）"
    echo ""
    echo "オプション:"
    echo "  --dry-run    - 実際のAWSリソースを作成せずに実行"
    echo "  --verbose    - 詳細なログ出力"
    echo "  --parallel   - 並行実行可能なテストを並行実行"
    echo "  --region     - AWSリージョンを指定"
    echo "  --profile    - AWSプロファイルを指定"
    echo "  -h, --help   - このヘルプを表示"
    echo ""
    echo "例:"
    echo "  $0 list                              # シナリオ一覧"
    echo "  $0 quick --dry-run                   # 高速テスト（dry-run）"
    echo "  $0 basic --parallel                  # 基本テスト（並行実行）"
    echo "  $0 full --verbose                    # 完全テスト（詳細ログ）"
    echo "  $0 integration --region us-east-1    # 統合テスト（us-east-1）"
    echo "  $0 cleanup                           # クリーンアップ"
    echo ""
    echo "注意事項:"
    echo "  - integration/fullテストは実際のAWSリソースを作成するため費用が発生します"
    echo "  - テスト完了後は自動的にリソースが削除されます"
    echo "  - 異常終了時は cleanup シナリオを実行してください"
}

# メイン処理
main() {
    log_suite "EC2 Test Suite Manager を開始します"
    log_suite "シナリオ: ${SCENARIO}"

    if [ "$DRY_RUN" = true ]; then
        log_warning "🧪 DRY-RUN モードで実行中（実際のAWSリソースは作成されません）"
    fi

    if [ "$VERBOSE" = true ]; then
        log_verbose "詳細ログモードが有効です"
    fi

    if [ "$PARALLEL" = true ]; then
        log_verbose "並行実行モードが有効です"
    fi

    # シナリオの実行
    run_scenario "$SCENARIO"

    # テスト結果の表示（listシナリオ以外）
    if [ "$SCENARIO" != "list" ]; then
        show_test_results
    fi

    log_suite "Test Suite Manager が完了しました"
}

# エラーハンドリング
trap 'log_error "スクリプトが予期せず終了しました。cleanup シナリオを実行してください。"; exit 1' ERR

# スクリプト実行
main "$@"
