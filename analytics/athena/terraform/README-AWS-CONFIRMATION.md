# AWS Account Confirmation for Terraform

このディレクトリには、AWS Account確認機能付きのTerraformラッパースクリプトが含まれています。

## 概要

Terraformコマンドを実行する前に、必ずAWS Account情報を確認し、Y/N選択を求める仕組みです。
これにより、誤った AWS Account でのデプロイを防ぐことができます。

## 使用方法

### 1. Terraform Plan (確認機能付き)

```bash
./terraform-plan.sh
```

### 2. Terraform Apply (確認機能付き)

```bash
./terraform-apply.sh
```

### 3. 通常のTerraformコマンドに引数を渡す

```bash
# terraform plan -out=plan.tfplan と同等
./terraform-plan.sh -out=plan.tfplan

# terraform apply -auto-approve と同等
./terraform-apply.sh -auto-approve
```

## 動作

1. **AWS情報取得**: `aws sts get-caller-identity` を使用してAWS Account情報を取得
2. **情報表示**: Account ID、User ID、ARNを色付きで表示
3. **確認プロンプト**: "Do you want to proceed with this AWS account? (y/N):"
4. **実行制御**:
   - `y` または `yes` → Terraformコマンドを実行
   - `n`、`no`、または無入力 → 実行を中止

## 表示例

```
🚨 AWS Account Confirmation Required! 🚨
==========================================

Retrieving AWS account information...

Current AWS Account Information:
- Account ID: 570240957699
- User ID: AIDAYJRICPUBTWY7H6EPO
- ARN: arn:aws:iam::570240957699:user/dh_y.ohi

⚠️  Please verify this is the correct AWS account!

Do you want to proceed with this AWS account? (y/N):
```

## エラーハンドリング

- AWS認証情報が設定されていない場合、エラーメッセージを表示して終了
- 確認でNoを選択した場合、安全に終了
- スクリプト実行中にエラーが発生した場合、`set -e` により自動的に終了

## 従来のコマンドとの比較

| 従来                              | 新しい方法                             |
| --------------------------------- | -------------------------------------- |
| `terraform plan`                  | `./terraform-plan.sh`                  |
| `terraform apply`                 | `./terraform-apply.sh`                 |
| `terraform plan -out=plan.tfplan` | `./terraform-plan.sh -out=plan.tfplan` |
| `terraform apply plan.tfplan`     | `./terraform-apply.sh plan.tfplan`     |

## セキュリティ機能

- ✅ 必ずAWS Account情報が表示される
- ✅ 明示的な確認なしには実行されない
- ✅ 色付き表示で視認性が高い
- ✅ エラー時の安全な終了
- ✅ 既存のTerraformワークフローとの互換性
