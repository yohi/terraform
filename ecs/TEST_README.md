# ECS モジュール テストガイド

このドキュメントでは、ECSモジュール（クラスターとサービス）のテストコードの使用方法について説明します。

## 📋 概要

ECSモジュールには包括的なテストスイートが含まれており、以下の観点からTerraformコードの品質を検証します：

- **ドキュメント**: README、変数説明、出力説明の完全性
- **構文**: Terraform構文とフォーマットの正確性
- **検証**: 変数の型、デフォルト値、検証ルールの確認
- **プラン**: Terraformプラン生成と期待されるリソースの確認
- **設定**: tfvars.exampleファイルの完全性と妥当性

## 🏗️ テスト構造

```
ecs/
├── cluster/
│   ├── tests/
│   │   ├── test_documentation_exists.sh      # ドキュメント存在確認
│   │   ├── test_outputs_structure.sh         # 出力構造検証
│   │   ├── test_variables_validation.sh      # 変数検証
│   │   ├── test_terraform_plan.sh            # Terraformプラン検証
│   │   └── test_tfvars_example.sh            # tfvars.example検証
│   ├── test_runner.sh                        # クラスター用テストランナー
│   └── terraform/                            # Terraformコード
├── service/
│   ├── tests/
│   │   └── test_documentation_exists.sh      # ドキュメント存在確認
│   ├── test_runner.sh                        # サービス用テストランナー
│   └── terraform/                            # Terraformコード
└── TEST_README.md                            # このファイル
```

## 🚀 使用方法

### ECSクラスターのテスト

```bash
# クラスターディレクトリに移動
cd ecs/cluster

# 全テスト実行
./test_runner.sh

# 詳細出力付き実行
./test_runner.sh -v

# 高速テストのみ実行
./test_runner.sh --fast-only

# 特定のテストのみ実行
./test_runner.sh -t test_documentation_exists

# 重いテストをスキップ
./test_runner.sh --skip-slow
```

### ECSサービスのテスト

```bash
# サービスディレクトリに移動
cd ecs/service

# 全テスト実行
./test_runner.sh

# 詳細出力付き実行
./test_runner.sh -v

# 高速テストのみ実行
./test_runner.sh --fast-only
```

### 個別テストの実行

```bash
# クラスターの特定テストを直接実行
cd ecs/cluster
bash tests/test_documentation_exists.sh

# サービスの特定テストを直接実行
cd ecs/service
bash tests/test_documentation_exists.sh
```

## ⚙️ テストランナーオプション

| オプション | 説明 | 例 |
|-----------|------|-----|
| `-v, --verbose` | 詳細な出力を表示 | `./test_runner.sh -v` |
| `-s, --sequential` | テストを順次実行（並列ではなく） | `./test_runner.sh -s` |
| `-t, --test NAME` | 特定のテストのみ実行 | `./test_runner.sh -t test_documentation_exists` |
| `--skip-slow` | 重いテスト（Terraformプランなど）をスキップ | `./test_runner.sh --skip-slow` |
| `--fast-only` | 高速テスト（ドキュメント、構文チェック）のみ実行 | `./test_runner.sh --fast-only` |
| `-h, --help` | ヘルプメッセージを表示 | `./test_runner.sh -h` |

## 🧪 テストタイプ

### 高速テスト (< 10秒)

1. **test_documentation_exists.sh**
   - README.mdの存在と内容確認
   - Terraformファイルの存在確認
   - 変数と出力の説明確認

2. **test_outputs_structure.sh**
   - 出力の構造と値の確認
   - 条件付き出力の論理確認

3. **test_variables_validation.sh**
   - 必須変数の確認
   - 変数の型と説明の確認
   - デフォルト値と検証ルールの確認

4. **test_tfvars_example.sh**
   - terraform.tfvars.exampleの存在と構文確認
   - 必須変数のカバレッジ確認

### 重いテスト (10秒以上)

1. **test_terraform_plan.sh**
   - 様々な設定でのTerraformプラン生成
   - リソース作成の確認
   - 設定検証の確認

## 🔧 前提条件

テストを実行するには以下のツールが必要です：

- **Terraform** (>= 1.0)
- **jq** (JSONパース用)
- **Bash** (>= 4.0)

### インストール方法

```bash
# macOS (Homebrew)
brew install terraform jq

# Ubuntu/Debian
sudo apt-get install terraform jq

# CentOS/RHEL
sudo yum install terraform jq
```

## 📊 テスト結果の理解

### 成功例
```
✅ test_documentation_exists passed (2s)
✅ test_terraform_plan passed (15s)
🎉 All tests passed!
```

### 失敗例
```
❌ test_documentation_exists failed (1s)
  ❌ Missing sections in README.md:
    - ## Container Configuration
    - ## Load Balancer Integration
💥 Some tests failed
```

### 警告例
```
⚠️  Documentation could be improved:
  - Missing auto scaling documentation
✅ test_documentation_exists passed (2s)
```

## 🐛 トラブルシューティング

### よくある問題

1. **Terraform初期化エラー**
   ```bash
   # 解決方法: .terraformディレクトリを削除
   rm -rf .terraform .terraform.lock.hcl
   ```

2. **権限エラー**
   ```bash
   # 解決方法: テストスクリプトに実行権限を付与
   chmod +x test_runner.sh tests/*.sh
   ```

3. **jqが見つからない**
   ```bash
   # 解決方法: jqをインストール
   sudo apt-get install jq  # Ubuntu/Debian
   brew install jq          # macOS
   ```

### デバッグ方法

```bash
# 詳細な出力でテスト実行
./test_runner.sh -v

# 特定のテストのみデバッグ
bash -x tests/test_documentation_exists.sh

# Terraformの詳細ログを有効化
export TF_LOG=DEBUG
./test_runner.sh -t test_terraform_plan
```

## 🔄 継続的インテグレーション

GitHubアクションやその他のCIシステムでテストを自動実行する例：

```yaml
# .github/workflows/test.yml
name: ECS Module Tests
on: [push, pull_request]

jobs:
  test-ecs-cluster:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
      - name: Install dependencies
        run: sudo apt-get update && sudo apt-get install -y jq
      - name: Run ECS Cluster Tests
        run: |
          cd ecs/cluster
          ./test_runner.sh --fast-only

  test-ecs-service:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
      - name: Install dependencies
        run: sudo apt-get update && sudo apt-get install -y jq
      - name: Run ECS Service Tests
        run: |
          cd ecs/service
          ./test_runner.sh --fast-only
```

## 📈 パフォーマンス

### テスト実行時間の目安

| テストセット | 高速テストのみ | 全テスト |
|------------|-------------|---------|
| ECSクラスター | ~10秒 | ~60秒 |
| ECSサービス | ~5秒 | ~30秒 |

### 最適化のヒント

1. **開発中は高速テストを使用**
   ```bash
   ./test_runner.sh --fast-only
   ```

2. **並列実行を活用**（デフォルトで有効）
   ```bash
   ./test_runner.sh  # 自動的に並列実行
   ```

3. **プルリクエスト前に全テスト実行**
   ```bash
   ./test_runner.sh -v
   ```

## 🤝 貢献方法

新しいテストを追加する場合：

1. **テストファイルの作成**
   ```bash
   # クラスター用
   touch ecs/cluster/tests/test_new_feature.sh
   chmod +x ecs/cluster/tests/test_new_feature.sh
   ```

2. **テンプレートの使用**
   ```bash
   #!/bin/bash
   set -euo pipefail

   # Colors for output
   readonly RED='\033[0;31m'
   readonly GREEN='\033[0;32m'
   readonly NC='\033[0m'

   print_status() {
       local color=$1
       local message=$2
       echo -e "${color}${message}${NC}"
   }

   # テスト関数を作成
   test_new_feature() {
       print_status "$BLUE" "  Testing new feature..."
       # テストロジックを実装
       return 0  # 成功時
   }

   # テスト実行
   if test_new_feature; then
       print_status "$GREEN" "✅ New feature test passed!"
       exit 0
   else
       print_status "$RED" "❌ New feature test failed!"
       exit 1
   fi
   ```

3. **テストランナーでの自動認識**
   テストファイルが`test_*.sh`の形式であれば、テストランナーが自動的に認識します。

## 📚 関連ドキュメント

- [ECS Cluster Module README](cluster/README.md)
- [ECS Service Module README](service/README.md)
- [Terraform Testing Best Practices](https://developer.hashicorp.com/terraform/language/tests)
- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)

## 🆘 サポート

質問や問題がある場合は、以下の方法でサポートを受けることができます：

1. **Issue作成**: GitHubリポジトリでIssueを作成
2. **ドキュメント確認**: 各モジュールのREADMEを確認
3. **テスト実行**: `-v`オプションで詳細ログを確認

---

**注意**: このテストスイートは開発とCI/CDプロセスの一部として使用することを想定しています。本番環境での使用前に、必ず適切な検証を行ってください。
