# S3バケット自動処理機能

このTerraform設定では、S3バケットが既に存在する場合の自動処理機能を提供します。

## 機能概要

### 1. 既存バケット検出
- **Athena結果バケット**: `{project}-{env}-athena-results`
- **ログバケット**: `{project}-{env}-logs-data`

これらのバケットが既に存在するかを自動的に確認します。

### 2. 動作パターン

#### パターン1: バケットが既に存在する場合
```
S3バケット 'rcs-stg-athena-results' は既に存在します。
既存のバケットを使用します。
```
→ **既存のバケットを使用し、新しいバケットは作成しません**

#### パターン2: バケットが存在しない場合（インタラクティブモード）
```
S3バケット 'rcs-stg-athena-results' は存在しません。
新しくバケットを作成しますか？ (y/n):
```

- **y** を選択 → 新しいバケットを作成
- **n** を選択 → 処理を中断

#### パターン3: バケットが存在しない場合（自動モード）
```
自動作成モードが有効です。バケットを作成します。
```
→ **確認なしで自動的に新しいバケットを作成**

## 設定方法

### 1. インタラクティブモード（デフォルト）
```hcl
auto_create_bucket = false
```

### 2. 自動作成モード（CI/CD向け）
```hcl
auto_create_bucket = true
```

または環境変数で設定：
```bash
export TF_VAR_auto_create_bucket=true
terraform plan
```

## 使用例

### 例1: 手動確認モード
```bash
terraform plan -var="project=rcs" -var="env=stg" -var="logs_s3_prefix=logs/containers"
```

### 例2: 自動作成モード（CI/CD）
```bash
terraform plan -var="project=rcs" -var="env=stg" -var="logs_s3_prefix=logs/containers" -var="auto_create_bucket=true"
```

## 注意事項

### 1. バケット名の重複
- AWS S3のバケット名はグローバルでユニークである必要があります
- 他のAWSアカウントで同じ名前のバケットが存在する場合、作成に失敗します

### 2. 権限要件
このスクリプトは以下のAWS権限が必要です：
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetBucketLocation",
        "s3:CreateBucket",
        "s3:PutBucketVersioning",
        "s3:PutBucketEncryption"
      ],
      "Resource": "*"
    }
  ]
}
```

### 3. 既存バケットの設定
既存のバケットを使用する場合：
- **暗号化設定**: Terraform管理外のため、手動で設定が必要
- **バージョニング**: Terraform管理外のため、手動で設定が必要
- **ライフサイクル**: Terraform管理外のため、手動で設定が必要

新しく作成されるバケットには、これらの設定が自動的に適用されます。

## トラブルシューティング

### エラー1: バケット作成に失敗
```
Error: error creating S3 bucket: BucketAlreadyExists
```
**解決方法**: 別のバケット名を使用するか、既存のバケットを削除してください。

### エラー2: 権限不足
```
Error: Access Denied
```
**解決方法**: IAMユーザー/ロールに適切なS3権限を付与してください。

### エラー3: スクリプト実行エラー
```
Error: external program returned error: s3_bucket_check.sh: command not found
```
**解決方法**: スクリプトファイルに実行権限を付与してください：
```bash
chmod +x s3_bucket_check.sh
```

## 開発者向け情報

### スクリプトファイル
- `s3_bucket_check.sh`: S3バケット存在確認スクリプト
- 戻り値: JSON形式で結果を返す

### Terraform設定
- `data.external`: バケット存在確認の実行
- `count`: 条件付きリソース作成
- `local`: 動的なバケット参照
