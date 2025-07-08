# ECR Repository Module Test Suite

このディレクトリには、ECR Repository モジュールのテストスイートが含まれています。テストスイートは、Terraform コード、設定ファイル、ドキュメントの品質と正確性を検証します。

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

- **コード品質の保証**: Terraform コードの構文と品質を検証
- **設定の検証**: 変数の妥当性とデフォルト値の確認
- **ECR機能のテスト**: ECR固有の機能（ライフサイクルポリシー、レプリケーション等）の動作確認
- **AWS統合のテスト**: AWS ECRサービスとの接続性を検証
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

# Docker (一部のテストで必要)
docker --version
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
# ECRモジュールのディレクトリに移動
cd ecr/repository

# 全テストを実行
./test_runner.sh
```

### 個別テストの実行

```bash
# 特定のテストのみ実行
./tests/test_terraform_plan.sh
./tests/test_variables_validation.sh
./tests/test_lifecycle_policy.sh
```

### テスト実行時の出力例

```
========================================
ECR Repository Module Test Suite
========================================

----------------------------------------
Prerequisites Check
----------------------------------------
✅ All required tools are available
✅ AWS credentials are configured

----------------------------------------
Terraform Tests
----------------------------------------
🔍 Running: terraform fmt check
✅ PASSED: terraform fmt check
🔍 Running: terraform validate
✅ PASSED: terraform validate
🔍 Running: terraform plan (dry run)
✅ PASSED: terraform plan (dry run)

----------------------------------------
ECR Specific Tests
----------------------------------------
🔍 Running: ECR repository creation test
✅ PASSED: ECR repository creation test
🔍 Running: lifecycle policy validation
✅ PASSED: lifecycle policy validation

----------------------------------------
Test Summary
----------------------------------------
Tests Passed:  18
Tests Failed:  0
Tests Skipped: 2
Total Tests:   20

🎉 All tests passed!
```

## 📊 テストの種類

### 1. Terraform Tests (Terraformテスト)
- **目的**: Terraform コードの構文と設定を検証
- **対象**: `main.tf`、`variables.tf`、`outputs.tf`
- **チェック内容**:
  - `terraform fmt` による形式チェック
  - `terraform validate` による構文検証
  - `terraform plan` による実行可能性確認（DryRun）

### 2. Configuration Tests (設定テスト)
- **目的**: 設定ファイルの整合性を検証
- **対象**: `terraform.tfvars.example`、変数定義
- **チェック内容**:
  - 設定ファイルの構文チェック
  - 必須変数の存在確認
  - 変数バリデーションルールの検証

### 3. ECR Specific Tests (ECR固有テスト)
- **目的**: ECR固有の機能を検証
- **対象**: ライフサイクルポリシー、リポジトリポリシー、複数リポジトリ設定
- **チェック内容**:
  - ECRリポジトリ作成の検証
  - ライフサイクルポリシーの動作確認
  - リポジトリポリシーの設定確認
  - 複数リポジトリの設定検証
  - Docker統合の動作確認

### 4. Integration Tests (統合テスト)
- **目的**: AWS ECRサービスとの統合を検証
- **対象**: AWS ECRサービス、リポジトリ命名規則、レプリケーション設定
- **チェック内容**:
  - AWS ECRサービスの可用性確認
  - リポジトリ命名規則の検証
  - レプリケーション設定の確認

### 5. Security Tests (セキュリティテスト)
- **目的**: セキュリティ設定を検証
- **対象**: 暗号化設定、スキャン設定、IAM権限
- **チェック内容**:
  - 暗号化設定の検証
  - スキャン設定の確認
  - IAM権限の妥当性確認

### 6. Documentation Tests (ドキュメントテスト)
- **目的**: ドキュメントの存在と品質を検証
- **対象**: README ファイル、設定例、Terraform例
- **チェック内容**:
  - 必須ドキュメントの存在確認
  - Markdown 構文チェック
  - Terraform例の構文確認
  - terraform.tfvars.example の完全性確認

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
  - 基本的なプラン生成
  - 複数リポジトリ設定のプラン生成
  - 不正な設定での検証エラーテスト

### test_variables_validation.sh
- **役割**: 変数バリデーション機能のテスト
- **機能**:
  - 環境変数の検証（dev, stg, prd, rls）
  - 暗号化設定の検証（AES256, KMS）
  - イメージタグ可変性の検証（MUTABLE, IMMUTABLE）
  - レプリケーション設定の検証

### test_lifecycle_policy.sh
- **役割**: ライフサイクルポリシー機能のテスト
- **機能**:
  - デフォルトライフサイクルポリシーの検証
  - カスタムライフサイクルポリシーの検証
  - ライフサイクルポリシー無効化のテスト
  - 不正なポリシーの処理確認

### test_outputs_structure.sh
- **役割**: 出力値の構造テスト
- **機能**:
  - 必須出力値の存在確認
  - 出力値の説明文の確認
  - 出力値の妥当性検証
  - ヘルパー出力値の確認
  - 後方互換性出力値の確認

### test_documentation_exists.sh
- **役割**: ドキュメント存在テスト
- **機能**:
  - README.md の存在と内容確認
  - 必須Terraformファイルの存在確認
  - README内のTerraform例の構文確認
  - terraform.tfvars.example のドキュメント化確認
  - versions.tf の内容確認

### test_tfvars_example.sh
- **役割**: terraform.tfvars.example のテスト
- **機能**:
  - ファイル存在確認
  - 構文チェック
  - 必須変数の存在確認
  - 例の値の妥当性確認

## 🔄 CI/CD統合

### GitHub Actions

```yaml
name: ECR Module Tests

on:
  push:
    paths:
      - 'ecr/repository/**'
  pull_request:
    paths:
      - 'ecr/repository/**'

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
        sudo apt-get install -y jq

    - name: Run ECR Module Tests
      run: |
        cd ecr/repository
        chmod +x test_runner.sh tests/*.sh
        ./test_runner.sh
```

### AWS CodeBuild

```yaml
version: 0.2

phases:
  install:
    runtime-versions:
      python: 3.9
    commands:
      - wget -O terraform.zip https://releases.hashicorp.com/terraform/1.5.0/terraform_1.5.0_linux_amd64.zip
      - unzip terraform.zip
      - mv terraform /usr/local/bin/
      - apt-get update
      - apt-get install -y jq

  build:
    commands:
      - cd ecr/repository
      - chmod +x test_runner.sh tests/*.sh
      - ./test_runner.sh
```

## 🐛 トラブルシューティング

### よくある問題と解決方法

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
cd ecr/repository/terraform
terraform init
```

#### 3. 依存関係の問題
```bash
# 症状: Missing required tools
# 解決方法:
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y jq

# macOS
brew install jq
```

#### 4. 権限エラー
```bash
# 症状: Permission denied
# 解決方法:
chmod +x test_runner.sh tests/*.sh
```

### デバッグモード

詳細なログを確認したい場合：

```bash
# デバッグモードで実行
bash -x ./test_runner.sh

# 特定のテストのみデバッグ
bash -x ./tests/test_lifecycle_policy.sh
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
- `tests/temp/`: 各テストの一時ファイル
- Terraform プランファイル（.tfplan）
- 設定ファイル（.tfvars）

## 🤝 貢献

### 新しいテストの追加

1. **テストスクリプトの作成**:
   ```bash
   # 新しいテストファイルを作成
   cp tests/test_template.sh tests/test_new_feature.sh
   ```

2. **test_runner.sh への追加**:
   ```bash
   # 適切なテストカテゴリ関数内に追加
   run_test "新機能のテスト" "./tests/test_new_feature.sh" false
   ```

3. **ドキュメントの更新**:
   - このREADMEファイルを更新
   - テストの説明を追加

### テストの改善

- **カバレッジの向上**: 新しいエッジケースの追加
- **パフォーマンスの改善**: 実行時間の短縮
- **エラーハンドリングの強化**: より詳細なエラーメッセージ

### コーディング規約

- **シェルスクリプト**: `set -euo pipefail` を使用
- **命名規則**: `test_<feature_name>.sh`
- **エラーハンドリング**: 適切なクリーンアップ関数の実装
- **出力形式**: 統一されたカラーコードと絵文字を使用

## 📝 ライセンス

このテストスイートは ECR Repository モジュールの一部として提供されています。

## 📞 サポート

問題や質問がある場合は、以下を確認してください：

1. [トラブルシューティング](#トラブルシューティング)セクション
2. 各テストスクリプトの詳細なエラーメッセージ
3. ECR Repository モジュールの README ファイル

---

**最終更新**: 2024年12月
**バージョン**: 1.0.0
**対応モジュール**: ECR Repository Module v1.0.0
