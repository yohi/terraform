# ECS Monitoring モジュール - テスト実行ガイド

このディレクトリには、ECS Monitoring モジュールのテストに関する情報が含まれています。

## テストファイル構成

```
ecs/monitoring/terraform/
├── basic.tftest.hcl          # 基本機能テスト
├── validation.tftest.hcl     # 入力検証テスト
├── integration.tftest.hcl    # 統合テスト
├── mocks.tftest.hcl          # モック設定
├── main.tf                   # メインモジュール
├── variables.tf              # 変数定義
├── outputs.tf                # 出力定義
└── terraform.tfvars.example  # 設定例
```

## テスト実行方法

### 1. 基本テスト（推奨）

モックプロバイダーを使用した高速テストです。AWS認証情報は不要です。

```bash
cd ecs/monitoring/terraform

# 基本機能テスト
terraform test basic.tftest.hcl

# 入力検証テスト
terraform test validation.tftest.hcl

# 両方のテストを実行
terraform test basic.tftest.hcl validation.tftest.hcl
```

### 2. 統合テスト（注意が必要）

実際のAWSリソースを使用するテストです。**AWSアカウントに課金が発生する可能性があります。**

```bash
# 事前準備：環境変数の設定
export AWS_PROFILE=your-test-profile
export TF_VAR_cluster_arn="arn:aws:ecs:ap-northeast-1:123456789012:cluster/your-test-cluster"
export TF_VAR_slack_token_secret_arn="arn:aws:secretsmanager:ap-northeast-1:123456789012:secret:your-slack-token"

# 統合テスト実行
terraform test integration.tftest.hcl
```

### 3. 全テスト実行

```bash
# 基本テストのみ（推奨）
terraform test basic.tftest.hcl validation.tftest.hcl

# 全テスト実行（AWS認証情報が必要）
terraform test
```

## テストの種類

### 基本機能テスト（basic.tftest.hcl）

- **目的**: モジュールの基本機能を検証
- **実行時間**: 高速（数秒）
- **AWS認証**: 不要（モック使用）
- **テスト内容**:
  - リソース作成の確認
  - 監視無効化の動作確認
  - リソース名生成の確認
  - Lambda設定の確認
  - タグ設定の確認
  - 出力値の確認

### 入力検証テスト（validation.tftest.hcl）

- **目的**: 変数のバリデーションルールを検証
- **実行時間**: 高速（数秒）
- **AWS認証**: 不要（モック使用）
- **テスト内容**:
  - 環境変数の有効/無効値テスト
  - ログ保持期間の有効/無効値テスト
  - Lambda設定の有効/無効値テスト
  - デフォルト値の確認

### 統合テスト（integration.tftest.hcl）

- **目的**: 実際のAWSリソースでの動作確認
- **実行時間**: 低速（数分）
- **AWS認証**: 必要
- **テスト内容**:
  - 実際のリソース作成/削除
  - IAMポリシーの確認
  - EventBridge設定の確認
  - Lambda環境変数の確認
  - 自動クリーンアップ

### モック設定（mocks.tftest.hcl）

- **目的**: テスト用のモックデータ定義
- **使用方法**: 他のテストファイルから参照
- **内容**:
  - AWSリソースのモック定義
  - テスト用のデフォルト値
  - モック使用例

## テスト実行時の注意事項

### 基本テスト・入力検証テスト

✅ **安全**: AWS認証情報不要、課金なし
✅ **高速**: 数秒で完了
✅ **CI/CD**: 自動化に適している

### 統合テスト

⚠️ **注意**: 実際のAWSリソースを作成/削除
⚠️ **課金**: AWSアカウントに課金が発生する可能性
⚠️ **権限**: 適切なIAM権限が必要
⚠️ **環境**: テスト用AWSアカウントでの実行を推奨

## 必要な権限（統合テスト実行時）

統合テストを実行する場合、以下のAWS権限が必要です：

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "events:*",
        "logs:*",
        "lambda:*",
        "iam:*",
        "secretsmanager:GetSecretValue"
      ],
      "Resource": "*"
    }
  ]
}
```

## トラブルシューティング

### テストが失敗する場合

1. **基本テスト失敗**:
   ```bash
   # Terraformの初期化
   terraform init

   # 構文チェック
   terraform validate

   # 詳細ログで実行
   TF_LOG=DEBUG terraform test basic.tftest.hcl
   ```

2. **統合テスト失敗**:
   ```bash
   # AWS認証情報の確認
   aws sts get-caller-identity

   # 権限の確認
   aws iam simulate-principal-policy --policy-source-arn $(aws sts get-caller-identity --query Arn --output text) --action-names events:CreateRule
   ```

### よくあるエラー

| エラー                                     | 原因                             | 解決方法                       |
| ------------------------------------------ | -------------------------------- | ------------------------------ |
| `Error: No valid credential sources found` | AWS認証情報が設定されていない    | AWS CLI設定またはIAM権限の確認 |
| `Error: validation failed`                 | 変数の値が無効                   | terraform.tfvarsの設定確認     |
| `Error: resource already exists`           | 統合テストのリソースが残っている | 手動でリソースを削除           |

## CI/CDでの使用

### GitHub Actions例

```yaml
name: Terraform Test
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3

      - name: Run basic tests
        run: |
          cd ecs/monitoring/terraform
          terraform init
          terraform test basic.tftest.hcl validation.tftest.hcl
```

### 推奨事項

- **基本テスト**: 全てのPR/pushで実行
- **統合テスト**: 本番環境以外で定期実行
- **並列実行**: 基本テストは並列実行可能
- **タイムアウト**: 統合テストには適切なタイムアウト設定

## 参考資料

- [Terraform Testing Documentation](https://developer.hashicorp.com/terraform/language/tests)
- [AWS Provider Testing](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/guides/testing)
- [Terraform Test Framework](https://developer.hashicorp.com/terraform/tutorials/configuration-language/test)
