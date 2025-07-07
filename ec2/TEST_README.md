# EC2 モジュール テストガイド

このドキュメントは、EC2モジュール（Launch Template および Auto Scaling Group）のテストコードの使用方法と構成について説明します。

## 📋 目次

1. [テストの概要](#テストの概要)
2. [テストファイルの構成](#テストファイルの構成)
3. [前提条件](#前提条件)
4. [テストの実行方法](#テストの実行方法)
5. [テストシナリオ](#テストシナリオ)
6. [トラブルシューティング](#トラブルシューティング)
7. [ベストプラクティス](#ベストプラクティス)
8. [FAQ](#faq)

## 🎯 テストの概要

EC2モジュールのテストスイートは、以下の3つのレベルでテストを提供します：

- **ユニットテスト**: 個別のモジュール（Launch Template、Auto Scaling Group）の動作確認
- **統合テスト**: 複数のモジュールの連携動作確認
- **エンドツーエンドテスト**: 実際のAWSリソースでの動作確認

## 📂 テストファイルの構成

```
ec2/
├── launch_template/
│   ├── test_module.sh              # Launch Template 単体テスト
│   └── terraform/                  # Terraform設定ファイル
├── auto_scaling_group/
│   ├── test_module.sh              # Auto Scaling Group 単体テスト
│   └── terraform/                  # Terraform設定ファイル
├── run_integration_tests.sh        # 統合テストスクリプト
├── test_suite.sh                   # テストスイート管理
└── TEST_README.md                  # このファイル
```

### 各テストファイルの説明

| ファイル名                          | 説明                            | 主な機能                                       |
| ----------------------------------- | ------------------------------- | ---------------------------------------------- |
| `launch_template/test_module.sh`    | Launch Template の単体テスト    | validate, plan, apply, destroy, check, cleanup |
| `auto_scaling_group/test_module.sh` | Auto Scaling Group の単体テスト | validate, plan, apply, destroy, check          |
| `run_integration_tests.sh`          | 統合テスト                      | full, validate, plan, apply, destroy, cleanup  |
| `test_suite.sh`                     | テストスイート管理              | 複数のテストシナリオを管理                     |

## 🔧 前提条件

### 必要なツール

- **AWS CLI**: バージョン 2.0 以降
- **Terraform**: バージョン 1.0 以降
- **jq**: JSON処理ツール
- **bash**: バージョン 4.0 以降

### インストール例（Ubuntu/Debian）

```bash
# AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Terraform
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# jq
sudo apt-get install jq
```

### AWS設定

```bash
# AWS認証情報の設定
aws configure

# 設定の確認
aws sts get-caller-identity
```

### 必要なIAM権限

テストを実行するIAMユーザーには、以下の権限が必要です：

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "autoscaling:*",
        "cloudwatch:*",
        "sns:*",
        "ssm:*",
        "iam:PassRole"
      ],
      "Resource": "*"
    }
  ]
}
```

## 🚀 テストの実行方法

### 1. 高速テスト（推奨開始点）

設定の検証と実行計画の作成のみを行います。AWSリソースは作成されません。

```bash
# テストスイートを使用
./test_suite.sh quick

# 統合テストを使用
./run_integration_tests.sh validate
```

### 2. 個別モジュールテスト

#### Launch Template テスト

```bash
cd launch_template

# 設定検証
./test_module.sh validate

# 実行計画
./test_module.sh plan

# リソース作成
./test_module.sh apply

# 状態確認
./test_module.sh check

# リソース削除
./test_module.sh destroy

# テストリソースクリーンアップ
./test_module.sh cleanup
```

#### Auto Scaling Group テスト

```bash
cd auto_scaling_group

# 設定検証
./test_module.sh validate

# 実行計画
./test_module.sh plan

# リソース作成
./test_module.sh apply

# 状態確認
./test_module.sh check

# リソース削除
./test_module.sh destroy
```

### 3. 統合テスト

Launch Template と Auto Scaling Group を連携してテストします。

```bash
# 完全統合テスト
./run_integration_tests.sh full

# 段階的実行
./run_integration_tests.sh validate
./run_integration_tests.sh plan
./run_integration_tests.sh apply
./run_integration_tests.sh check
./run_integration_tests.sh destroy
```

### 4. テストスイート（推奨）

複数のテストシナリオを管理します。

```bash
# 利用可能なシナリオを表示
./test_suite.sh list

# 高速テスト
./test_suite.sh quick

# 基本テスト
./test_suite.sh basic

# 統合テスト
./test_suite.sh integration

# 完全テスト
./test_suite.sh full

# セキュリティテスト
./test_suite.sh security

# パフォーマンステスト
./test_suite.sh performance

# クリーンアップ
./test_suite.sh cleanup
```

## 📊 テストシナリオ

### 1. quick (高速テスト)
- **目的**: 基本的な設定確認
- **実行時間**: 約2-5分
- **AWSリソース**: 作成されない
- **内容**:
  - Launch Template の設定検証
  - Auto Scaling Group の設定検証
  - 実行計画の作成

### 2. basic (基本テスト)
- **目的**: 各モジュールの個別動作確認
- **実行時間**: 約10-15分
- **AWSリソース**: 作成される
- **内容**:
  - Launch Template の完全テスト
  - Auto Scaling Group の完全テスト
  - 各モジュールの独立したテスト

### 3. integration (統合テスト)
- **目的**: モジュール間の連携確認
- **実行時間**: 約15-20分
- **AWSリソース**: 作成される
- **内容**:
  - Launch Template → Auto Scaling Group の順序テスト
  - データの受け渡し確認
  - 依存関係の確認

### 4. full (完全テスト)
- **目的**: 全機能の包括的テスト
- **実行時間**: 約30-45分
- **AWSリソース**: 作成される
- **内容**:
  - 高速 + 基本 + 統合 + セキュリティ + パフォーマンス

### 5. security (セキュリティテスト)
- **目的**: セキュリティ設定の確認
- **実行時間**: 約5-10分
- **AWSリソース**: 限定的
- **内容**:
  - IAM権限の確認
  - セキュリティグループの設定確認
  - Parameter Store アクセス確認

### 6. performance (パフォーマンステスト)
- **目的**: スケーリング動作の確認
- **実行時間**: 約20-30分
- **AWSリソース**: 作成される
- **内容**:
  - Auto Scaling Group のスケーリング動作
  - 負荷テスト（シミュレーション）

### 7. cleanup (クリーンアップ)
- **目的**: テストリソースの削除
- **実行時間**: 約5-10分
- **AWSリソース**: 削除される
- **内容**:
  - 作成されたAWSリソースの削除
  - 設定ファイルのクリーンアップ

## 🎛️ Dry-run モード

実際のAWSリソースを作成せずにテストの流れを確認できます。

```bash
# 統合テストをdry-runで実行
./test_suite.sh integration dry-run

# 完全テストをdry-runで実行
./test_suite.sh full dry-run
```

## 📝 テスト設定のカスタマイズ

### terraform.tfvars の手動設定

自動生成される設定ファイルをカスタマイズできます：

```bash
# Launch Template の設定
cd launch_template/terraform
cp terraform.tfvars.example terraform.tfvars
vi terraform.tfvars

# Auto Scaling Group の設定
cd auto_scaling_group/terraform
cp terraform.tfvars.example terraform.tfvars
vi terraform.tfvars
```

### 主要な設定項目

```hcl
# Launch Template 設定例
project_name = "my-project"
environment  = "dev"
instance_type = "t3.medium"
volume_size   = 30

# Auto Scaling Group 設定例
project = "my-project"
env     = "dev"
min_size         = 1
desired_capacity = 2
max_size         = 4
```

## 🔧 トラブルシューティング

### よくある問題と解決方法

#### 1. AWS認証エラー

```
Error: AWS認証情報が設定されていません
```

**解決方法**:
```bash
aws configure
# または
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="ap-northeast-1"
```

#### 2. IAM権限エラー

```
Error: User: arn:aws:iam::123456789012:user/test-user is not authorized to perform: ec2:CreateLaunchTemplate
```

**解決方法**:
- IAMユーザーに適切な権限を付与
- 必要な権限は[前提条件](#必要なiam権限)を参照

#### 3. キーペアエラー

```
Error: InvalidKeyPair.NotFound
```

**解決方法**:
```bash
# テストスクリプトが自動でキーペアを作成
# または手動で作成
aws ec2 create-key-pair --key-name my-key
```

#### 4. VPCエラー

```
Error: デフォルトVPCが見つかりません
```

**解決方法**:
```bash
# デフォルトVPCの作成
aws ec2 create-default-vpc
```

#### 5. Terraform状態エラー

```
Error: Resource already exists
```

**解決方法**:
```bash
# 状態ファイルの削除
cd terraform
rm -f terraform.tfstate terraform.tfstate.backup
terraform init
```

### ログの確認

各テストスクリプトは詳細なログを出力します：

```bash
# 色付きログが表示されます
[INFO] テストを開始します
[SUCCESS] ✅ テストが成功しました
[WARNING] ⚠️  注意が必要な項目があります
[ERROR] ❌ エラーが発生しました
```

### デバッグモード

詳細なデバッグ情報を表示するには：

```bash
# デバッグモードでテスト実行
set -x
./test_suite.sh quick
set +x
```

## 📊 テスト結果の確認

### テスト完了後の出力例

```
==========================================
テスト結果サマリー
==========================================
実行シナリオ: integration
実行時間: 180秒
総テスト数: 8
成功: 8
失敗: 0
成功率: 100%
==========================================

詳細結果:
✅ Launch Template - 設定検証
✅ Launch Template - 実行計画
✅ Launch Template - リソース作成
✅ Launch Template - 状態確認
✅ Auto Scaling Group - 設定検証
✅ Auto Scaling Group - 実行計画
✅ Auto Scaling Group - リソース作成
✅ Auto Scaling Group - 状態確認

🎉 全てのテストが成功しました！
```

### 作成されるリソースの確認

```bash
# 作成されたリソースの確認
aws ec2 describe-launch-templates --query 'LaunchTemplates[?contains(LaunchTemplateName, `test-lt`)].{Name:LaunchTemplateName,Id:LaunchTemplateId}'

aws autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[?contains(AutoScalingGroupName, `test-asg`)].{Name:AutoScalingGroupName,MinSize:MinSize,MaxSize:MaxSize,DesiredCapacity:DesiredCapacity}'
```

## 🔄 継続的インテグレーション

### GitHub Actions の設定例

```yaml
name: EC2 Module Tests

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2

    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v1
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: ap-northeast-1

    - name: Install dependencies
      run: |
        wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
        unzip terraform_1.6.0_linux_amd64.zip
        sudo mv terraform /usr/local/bin/
        sudo apt-get install jq

    - name: Run quick tests
      run: |
        cd ec2
        ./test_suite.sh quick

    - name: Run integration tests
      run: |
        cd ec2
        ./test_suite.sh integration

    - name: Cleanup
      if: always()
      run: |
        cd ec2
        ./test_suite.sh cleanup
```

## 🛡️ ベストプラクティス

### 1. テストの実行順序

```bash
# 推奨順序
./test_suite.sh quick      # 1. 高速テストで基本確認
./test_suite.sh basic      # 2. 基本テストで個別動作確認
./test_suite.sh integration # 3. 統合テストで連携確認
./test_suite.sh cleanup    # 4. クリーンアップでリソース削除
```

### 2. 環境分離

```bash
# 異なる環境での並行テスト
export AWS_PROFILE=test-dev
./test_suite.sh integration

export AWS_PROFILE=test-stg
./test_suite.sh integration
```

### 3. コスト管理

```bash
# dry-runで事前確認
./test_suite.sh full dry-run

# 実際のテスト実行
./test_suite.sh full

# 必ずクリーンアップを実行
./test_suite.sh cleanup
```

### 4. エラーハンドリング

```bash
# エラー発生時の自動クリーンアップ
trap './test_suite.sh cleanup' EXIT
./test_suite.sh full
```

## ❓ FAQ

### Q1: テストにかかる費用はどの程度ですか？

**A1**:
- `quick`テスト: 無料（リソース作成なし）
- `basic`テスト: 約$0.10-0.50/回（t3.microインスタンス使用）
- `integration`テスト: 約$0.20-1.00/回（複数リソース使用）
- `full`テスト: 約$0.50-2.00/回（全機能テスト）

### Q2: テストが失敗した場合、リソースは自動削除されますか？

**A2**:
- テストスクリプトは基本的に自動削除を行いますが、失敗時には手動でクリーンアップが必要な場合があります
- `./test_suite.sh cleanup` を実行してください

### Q3: 複数のリージョンでテストできますか？

**A3**:
- 可能です。AWS_DEFAULT_REGION環境変数を設定するか、terraform.tfvarsでリージョンを指定してください

```bash
export AWS_DEFAULT_REGION=us-west-2
./test_suite.sh integration
```

### Q4: 既存のリソースと競合しませんか？

**A4**:
- テストスクリプトは `test-` プレフィックスを使用してリソースを作成するため、既存のリソースとは競合しません
- ただし、リソース制限（VPC制限など）には注意が必要です

### Q5: Windows環境でテストできますか？

**A5**:
- WSL（Windows Subsystem for Linux）またはGit BashでBashスクリプトを実行できます
- PowerShellネイティブ版は現在提供していません

### Q6: テストの並行実行は可能ですか？

**A6**:
- 異なるAWSアカウントまたはリージョンでは並行実行可能です
- 同一アカウント・リージョンでは、リソース名の競合により並行実行は推奨されません

## 📞 サポート

### 問題報告

テストに関する問題やバグを発見した場合：

1. 問題の詳細（エラーメッセージ、実行コマンド、環境情報）
2. 再現手順
3. 期待される結果と実際の結果

### 貢献

テストの改善や新しいテストケースの追加：

1. フォークして新しいブランチを作成
2. テストケースを追加
3. プルリクエストを作成

### 連絡先

- GitHub Issues: [リポジトリのIssues](https://github.com/your-org/terraform-modules/issues)
- Email: devops@your-company.com

---

## 📚 参考資料

- [Terraform公式ドキュメント](https://www.terraform.io/docs/)
- [AWS CLI リファレンス](https://docs.aws.amazon.com/cli/)
- [Auto Scaling Group ガイド](https://docs.aws.amazon.com/autoscaling/ec2/userguide/)
- [Launch Template ガイド](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-launch-templates.html)

最終更新: 2024年12月
