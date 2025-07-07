# Analytics Infrastructure Test Suite

このディレクトリには、analytics フォルダー内のインフラストラクチャコードとスクリプトのテストスイートが含まれています。テストスイートは、Terraform コード、シェルスクリプト、設定ファイル、およびドキュメントの品質と正確性を検証します。

## 📋 目次

- [概要](#概要)
- [前提条件](#前提条件)
- [テストの実行](#テストの実行)
- [テストの種類](#テストの種類)
- [個別テストの説明](#個別テストの説明)
- [CI/CD統合](#cicd統合)
- [トラブルシューティング](#トラブルシューティング)
- [貢献](#貢献)

## 🎯 概要

このテストスイートは以下の目的で作成されています：

- **コード品質の保証**: Terraform コードとシェルスクリプトの構文と品質を検証
- **設定の検証**: 変数の妥当性とデフォルト値の確認
- **AWS統合のテスト**: AWS アカウントとリソースの接続性を検証
- **ドキュメントの整合性**: 必要なドキュメントの存在と内容を確認
- **回帰テストの防止**: コード変更による意図しない破綻を防止

## 🔧 前提条件

### 必須ツール

以下のツールがインストールされている必要があります：

```bash
# Terraform
terraform --version  # >= 1.0

# AWS CLI
aws --version  # >= 2.0

# jq (JSON処理)
jq --version

# ShellCheck (シェルスクリプト静的解析)
shellcheck --version
```

### AWS認証情報

一部のテストはAWS APIを使用するため、有効なAWS認証情報が必要です：

```bash
# AWS認証情報の設定
aws configure

# または環境変数
export AWS_ACCESS_KEY_ID=your_key
export AWS_SECRET_ACCESS_KEY=your_secret
export AWS_DEFAULT_REGION=ap-northeast-1
```

**注意**: AWS認証情報が設定されていない場合、関連するテストは自動的にスキップされます。

## 🚀 テストの実行

### 全テストの実行

```bash
# tests ディレクトリに移動
cd analytics/tests

# 全テストを実行
./test_runner.sh
```

### 個別テストの実行

```bash
# 特定のテストのみ実行
./test_terraform_plan.sh
./test_variables_validation.sh
./test_aws_account_flow.sh
```

### テスト実行時の出力例

```
========================================
Analytics Infrastructure Test Suite
========================================

----------------------------------------
Prerequisites Check
----------------------------------------
✅ All required tools are available
✅ AWS credentials are configured

----------------------------------------
Script Tests
----------------------------------------
🔍 Running: check_aws_account.sh syntax
✅ PASSED: check_aws_account.sh syntax
🔍 Running: check_aws_account.sh shellcheck
✅ PASSED: check_aws_account.sh shellcheck

----------------------------------------
Test Summary
----------------------------------------
Tests Passed:  15
Tests Failed:  0
Tests Skipped: 2
Total Tests:   17

🎉 All tests passed!
```

## 📊 テストの種類

### 1. Script Tests (スクリプトテスト)
- **目的**: シェルスクリプトの構文と品質を検証
- **対象**: `check_aws_account.sh`、各種 Terraform 実行スクリプト
- **チェック内容**:
  - Bash 構文チェック
  - ShellCheck による静的解析
  - 実行可能性の確認

### 2. Terraform Tests (Terraformテスト)
- **目的**: Terraform コードの構文と設定を検証
- **対象**: `main.tf`、`variables.tf`、`outputs.tf`
- **チェック内容**:
  - `terraform fmt` による形式チェック
  - `terraform validate` による構文検証
  - `terraform plan` による実行可能性確認（DryRun）

### 3. Configuration Tests (設定テスト)
- **目的**: 設定ファイルの整合性を検証
- **対象**: `terraform.tfvars.example`、変数定義
- **チェック内容**:
  - 設定ファイルの構文チェック
  - 必須変数の存在確認
  - 変数バリデーションルールの検証

### 4. Integration Tests (統合テスト)
- **目的**: AWSとの統合機能を検証
- **対象**: AWS アカウント接続、S3 バケット検証
- **チェック内容**:
  - AWS 認証情報の有効性
  - アカウント情報の取得
  - リソース存在チェック

### 5. Documentation Tests (ドキュメントテスト)
- **目的**: ドキュメントの存在と品質を検証
- **対象**: README ファイル、設定例、テンプレート
- **チェック内容**:
  - 必須ドキュメントの存在確認
  - Markdown 構文チェック
  - 内容の妥当性確認

## 🔍 個別テストの説明

### test_runner.sh
- **役割**: メインのテストランナー
- **機能**:
  - 前提条件チェック
  - 全テストの順次実行
  - テスト結果の集計とレポート

### test_terraform_plan.sh
- **役割**: Terraform プランの生成テスト
- **機能**:
  - 一時的な設定でのプラン生成
  - リソース数の確認
  - プランファイルの検証

### test_variables_validation.sh
- **役割**: 変数バリデーション機能のテスト
- **機能**:
  - 有効・無効な変数値での検証
  - エラーハンドリングの確認
  - バリデーションルールの動作確認

### test_aws_account_flow.sh
- **役割**: AWS アカウント検証フローのテスト
- **機能**:
  - AWS 認証情報の確認
  - アカウント情報の取得
  - Terraform でのアカウント検証

### test_s3_bucket_validation.sh
- **役割**: S3 バケット検証機能のテスト
- **機能**:
  - バケット存在チェック
  - バケット作成設定の検証
  - エラーハンドリングの確認

## 🔄 CI/CD統合

### GitHub Actions の例

```yaml
name: Analytics Infrastructure Tests

on:
  push:
    paths:
      - 'analytics/**'
  pull_request:
    paths:
      - 'analytics/**'

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.5.0

      - name: Install dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y jq shellcheck

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ap-northeast-1

      - name: Run tests
        run: |
          cd analytics/tests
          ./test_runner.sh
```

### Jenkins の例

```groovy
pipeline {
    agent any

    stages {
        stage('Setup') {
            steps {
                sh '''
                    # Install required tools
                    terraform --version || (curl -fsSL https://releases.hashicorp.com/terraform/1.5.0/terraform_1.5.0_linux_amd64.zip -o terraform.zip && unzip terraform.zip && sudo mv terraform /usr/local/bin/)
                    aws --version || pip install awscli
                    jq --version || sudo apt-get install -y jq
                    shellcheck --version || sudo apt-get install -y shellcheck
                '''
            }
        }

        stage('Test') {
            steps {
                sh '''
                    cd analytics/tests
                    ./test_runner.sh
                '''
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'analytics/tests/*.log', allowEmptyArchive: true
        }
    }
}
```

## 🛠️ トラブルシューティング

### 一般的な問題と解決方法

#### 1. AWS認証エラー
```bash
# 症状: AWS credentials are not working
# 解決方法:
aws configure list
aws sts get-caller-identity
```

#### 2. Terraform初期化エラー
```bash
# 症状: Terraform init failed
# 解決方法:
cd analytics/athena/terraform
terraform init
```

#### 3. 依存関係の問題
```bash
# 症状: Missing required tools
# 解決方法:
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y jq shellcheck

# macOS
brew install jq shellcheck
```

#### 4. 権限エラー
```bash
# 症状: Permission denied
# 解決方法:
chmod +x analytics/tests/*.sh
```

### デバッグモード

詳細なログを確認したい場合：

```bash
# デバッグモードで実行
bash -x ./test_runner.sh

# 特定のテストのみデバッグ
bash -x ./test_terraform_plan.sh
```

## 📈 テスト結果の解釈

### 終了コード
- **0**: 全テスト成功
- **1**: 一部テスト失敗
- **2**: 重大なエラー（依存関係不足など）

### 出力の色分け
- **🟢 緑**: 成功
- **🟡 黄**: 警告・スキップ
- **🔴 赤**: 失敗・エラー
- **🔵 青**: 情報・実行中

### ログファイル
テスト実行時に生成されるログファイル：
- `test_runner.log`: 全体のテスト結果
- `terraform_plan.log`: Terraform プランの詳細
- `aws_account.log`: AWS アカウント情報

## 🤝 貢献

### 新しいテストの追加

1. **テストスクリプトの作成**:
   ```bash
   # 新しいテストファイルを作成
   cp test_template.sh test_new_feature.sh
   ```

2. **test_runner.sh への追加**:
   ```bash
   # run_xxx_tests() 関数内に追加
   run_test "新機能のテスト" "./test_new_feature.sh" false
   ```

3. **ドキュメントの更新**:
   - このREADMEファイルを更新
   - テストの説明を追加

### テストの改善

- **カバレッジの向上**: 新しいエッジケースの追加
- **パフォーマンスの改善**: 実行時間の短縮
- **エラーハンドリングの強化**: より詳細なエラーメッセージ

### コーディング規約

- **シェルスクリプト**: ShellCheck に準拠
- **命名規則**: `test_<feature_name>.sh`
- **エラーハンドリング**: `set -euo pipefail` を使用
- **出力形式**: 統一されたカラーコードと絵文字を使用

## 📝 ライセンス

このテストスイートは analytics インフラストラクチャプロジェクトの一部として提供されています。

## 📞 サポート

問題や質問がある場合は、以下を確認してください：

1. [トラブルシューティング](#トラブルシューティング)セクション
2. 各テストスクリプトの詳細なエラーメッセージ
3. Analytics プロジェクトの README ファイル

---

**最終更新**: 2024年
**バージョン**: 1.0.0
