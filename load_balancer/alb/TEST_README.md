# ALB Module テストガイド

このドキュメントは、ALB (Application Load Balancer) モジュールのテストスイートについて説明します。

## 📋 テスト概要

ALBモジュールのテストスイートは、以下の要素を包括的に検証します：

- **ドキュメント検証**: README、変数説明、出力説明の完整性
- **Terraform構文**: プラン生成、変数検証、出力構造
- **ALB設定**: ロードバランサー、ターゲットグループ、リスナーの設定
- **セキュリティ**: セキュリティグループルール、HTTPS設定
- **命名規則**: 一貫した命名パターンとタグ戦略
- **ECS最適化**: ECS用の設定とベストプラクティス

## 🚀 テスト実行方法

### 前提条件

以下のツールがインストールされている必要があります：

```bash
# 必須ツール
terraform --version  # Terraform CLI
jq --version         # JSON処理ツール
bash --version       # Bashシェル
```

### 基本的な実行方法

```bash
# すべてのテストを実行
./test_runner.sh

# 詳細出力でテストを実行
./test_runner.sh -v

# 特定のテストのみ実行
./test_runner.sh -t test_documentation_exists

# 低速テストをスキップ
./test_runner.sh --skip-slow

# 逐次実行（並列実行を無効化）
./test_runner.sh -s

# ヘルプを表示
./test_runner.sh -h
```

### 使用例

```bash
# 開発時の高速テスト
./test_runner.sh --skip-slow

# CI/CD用の完全テスト
./test_runner.sh -v

# 特定の機能のテスト
./test_runner.sh -t test_alb_configuration
./test_runner.sh -t test_security_group_rules
```

## 📁 テストファイル構成

### テストランナー

- **`test_runner.sh`**: メインのテストランナー
  - 並列/逐次実行の選択
  - 詳細出力オプション
  - 特定テストの実行
  - 低速テストのスキップ

### 個別テストファイル

#### `test_documentation_exists.sh`
**目的**: ドキュメントの存在と内容を検証

**検証項目**:
- README.mdの存在と必須セクション
- Terraformファイルの存在
- 変数と出力の説明
- 設定例ファイルの確認

#### `test_terraform_plan.sh`
**目的**: Terraformプランの生成と検証

**検証項目**:
- 基本的なALB設定でのプラン生成
- 内部ALB設定
- アクセスログ設定
- HTTPS ターゲットグループ
- 無効な設定での検証エラー

#### `test_outputs_structure.sh`
**目的**: 出力値の構造と完整性を検証

**検証項目**:
- 必須出力値の存在
- ALB関連出力（ID、ARN、DNS名など）
- ターゲットグループ出力
- リスナー出力
- セキュリティグループ出力
- 接続情報出力

#### `test_tfvars_example.sh`
**目的**: 設定例ファイルの妥当性を検証

**検証項目**:
- ファイルの存在とHCL構文
- 必須変数の設定
- 設定値の妥当性（VPC ID形式、SSL証明書ARNなど）
- ALB固有設定の包括性
- タグ構造とコメント

#### `test_variables_validation.sh`
**目的**: 変数定義と検証ルールを確認

**検証項目**:
- 必須変数の定義
- 変数型の正確性
- 検証ルール（environment、subnet_ids、protocolsなど）
- デフォルト値の妥当性
- セキュリティ関連変数
- ALB固有変数
- ヘルスチェック変数

#### `test_alb_configuration.sh`
**目的**: ALB固有の設定を詳細に検証

**検証項目**:
- ALBリソース定義
- ターゲットグループ設定
- リスナー設定（HTTP/HTTPS）
- セキュリティグループ設定
- 命名規則の実装
- タグ戦略
- ECS最適化設定
- HTTPS リダイレクト
- ヘルスチェック設定

#### `test_security_group_rules.sh`
**目的**: セキュリティグループルールの詳細検証

**検証項目**:
- HTTP ingress ルール（IPv4/IPv6）
- HTTPS ingress ルール（IPv4/IPv6）
- Egress ルール
- セキュリティグループ命名
- タグ設定
- ライフサイクル設定
- ポート範囲設定
- 追加セキュリティグループサポート

## 🔧 テスト設定

### 環境変数

```bash
# テスト用の一時ディレクトリ
export TEST_TEMP_DIR="/tmp/alb_module_tests"

# Terraformのログレベル
export TF_LOG="INFO"

# 並列実行の最大数
export MAX_PARALLEL_TESTS=4
```

### テスト用設定ファイル

テストでは以下のサンプル設定を使用します：

```hcl
# 基本設定
project_name = "test-alb"
environment  = "dev"
vpc_id       = "vpc-12345678"
subnet_ids   = ["subnet-12345678", "subnet-87654321"]
ssl_certificate_arn = "arn:aws:acm:ap-northeast-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
```

## 📊 テスト結果の理解

### 終了コード

- `0`: すべてのテストが成功
- `1`: 1つ以上のテストが失敗

### 出力の意味

- ✅ **成功**: テストが正常に完了
- ❌ **失敗**: テストが失敗（修正が必要）
- ⚠️ **警告**: 推奨事項に関する警告（必須ではない）
- 🧪 **実行中**: テストが実行中
- ⏭️ **スキップ**: テストがスキップされた

### パフォーマンス情報

```bash
📊 Results:
  ✅ Passed: 8
  ❌ Failed: 0
  ⏭️  Skipped: 1
  📈 Total: 9
  ⏱️  Duration: 25s
```

## 🐛 トラブルシューティング

### よくある問題

#### 1. Terraform初期化エラー

```bash
❌ Failed to initialize Terraform
```

**解決方法**:
```bash
# Terraformバージョンを確認
terraform --version

# プロバイダーの更新
cd terraform/
terraform init -upgrade
```

#### 2. jqコマンドが見つからない

```bash
❌ Missing required tools: jq
```

**解決方法**:
```bash
# Ubuntu/Debian
sudo apt-get install jq

# CentOS/RHEL
sudo yum install jq

# macOS
brew install jq
```

#### 3. プラン生成の失敗

```bash
❌ Failed to generate basic ALB plan
```

**解決方法**:
1. variables.tfの検証ルールを確認
2. terraform.tfvars.exampleの設定値を確認
3. AWSプロバイダーのバージョン互換性を確認

#### 4. 権限エラー

```bash
bash: ./test_runner.sh: Permission denied
```

**解決方法**:
```bash
chmod +x test_runner.sh
chmod +x tests/*.sh
```

### デバッグ方法

#### 詳細出力でのテスト実行

```bash
./test_runner.sh -v
```

#### 特定テストの個別実行

```bash
cd tests/
bash test_terraform_plan.sh
```

#### Terraformのデバッグ

```bash
export TF_LOG=DEBUG
./test_runner.sh -t test_terraform_plan
```

## 📈 テストの拡張

### 新しいテストの追加

1. `tests/` ディレクトリに `test_*.sh` ファイルを作成
2. 既存のテストパターンに従って実装
3. `test_runner.sh` が自動的に新しいテストを検出

### テストテンプレート

```bash
#!/bin/bash

# Test [Description] for ALB Module

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Test directory
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="${TEST_DIR}/../terraform"

test_example_function() {
    print_status "$BLUE" "  Testing example functionality..."

    # テストロジックをここに実装

    if [ condition ]; then
        print_status "$GREEN" "  ✅ Test passed"
        return 0
    else
        print_status "$RED" "  ❌ Test failed"
        return 1
    fi
}

# Run all tests
main() {
    print_status "$BLUE" "Running example tests..."

    local tests=(
        "test_example_function"
    )

    local failed_tests=0

    for test in "${tests[@]}"; do
        if ! $test; then
            ((failed_tests++))
        fi
    done

    if [ $failed_tests -eq 0 ]; then
        print_status "$GREEN" "✅ All example tests passed"
        exit 0
    else
        print_status "$RED" "❌ $failed_tests example tests failed"
        exit 1
    fi
}

# Run main function
main "$@"
```

## 🔗 関連リソース

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [ALB Documentation](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/)
- [ECS Integration with ALB](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-load-balancing.html)
- [Blue-Green Deployment with ALB](https://developer.hashicorp.com/terraform/tutorials/aws/blue-green-canary-tests-deployments)

## 📞 サポート

テストに関する問題や改善提案がある場合は、以下の手順で報告してください：

1. 詳細出力でテストを実行: `./test_runner.sh -v`
2. エラーメッセージとテスト環境の情報を収集
3. 再現可能な手順を明確に記載
4. 期待する動作と実際の動作の違いを説明

---

**注意**: このテストスイートは開発・検証環境での使用を想定しています。本番環境での直接実行は避けてください。
