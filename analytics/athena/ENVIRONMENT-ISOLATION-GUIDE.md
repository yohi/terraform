# Athena環境分離実装ガイド

## 概要

このドキュメントでは、Athenaワークグループで環境ごとのアクセス制御を実装する方法について説明します。
この実装により、`rcs-stg-analysys`ワークグループでは`rcs_stg_web_log`テーブルのみアクセス可能になり、
`rcs_prd_web_log`などの他環境のテーブルは表示されなくなります。

## 実装された環境分離の仕組み

### 1. IAMロールベースのアクセス制御

#### ワークグループユーザー用ロール
- **ロール名**: `{project}-{env}-athena-workgroup-user-role`
- **用途**: 一般ユーザーの環境分離されたアクセス
- **制限事項**:
  - 指定されたワークグループのみアクセス可能
  - 指定されたデータベースのみアクセス可能
  - 他環境のデータベース・テーブルへのアクセスを明示的に拒否

#### 管理者用ポリシー
- **ポリシー名**: `{project}-{env}-athena-admin-policy`
- **用途**: データベース・テーブルの作成・更新権限を持つ管理者アクセス
- **制限事項**:
  - 指定されたワークグループとデータベースのみフルアクセス

### 2. アクセス制御の詳細

#### 許可されるアクション（ユーザーロール）
```json
{
  "athena:*": ["指定されたワークグループのみ"],
  "glue:Get*": ["指定されたデータベース・テーブルのみ"],
  "s3:GetObject": ["クエリ結果とログデータの読み取りのみ"]
}
```

#### 拒否されるアクション（Denyポリシー）
```json
{
  "glue:*": ["他環境のデータベース・テーブル"],
  "athena:*": ["他のワークグループ"]
}
```

## 使用方法

### 管理者の作業

1. **Terraformの適用**
   ```bash
   cd analytics/athena/terraform
   terraform plan
   terraform apply
   ```

2. **IAMロール・ポリシーの確認**
   ```bash
   terraform output workgroup_user_role_arn
   terraform output athena_admin_policy_arn
   ```

### ユーザーへのアクセス付与

#### 一般ユーザー（閲覧・クエリ実行のみ）
```bash
# ユーザーまたはグループにロールの引き受け権限を付与
aws iam attach-user-policy \
  --user-name <ユーザー名> \
  --policy-arn "arn:aws:iam::<アカウントID>:policy/AssumeWorkgroupUserRole"

# または既存のロールにワークグループユーザーロールの引き受け権限を追加
aws iam attach-role-policy \
  --role-name <既存ロール名> \
  --policy-arn $(terraform output -raw workgroup_user_role_arn | sed 's/role/policy/')
```

#### 管理者ユーザー（フルアクセス）
```bash
# 管理者ポリシーを直接アタッチ
aws iam attach-user-policy \
  --user-name <管理者ユーザー名> \
  --policy-arn $(terraform output -raw athena_admin_policy_arn)
```

### ユーザーの利用方法

#### AWS CLIでのロール切り替え
```bash
# ワークグループユーザーロールに切り替え
aws sts assume-role \
  --role-arn $(terraform output -raw workgroup_user_role_arn) \
  --role-session-name athena-access

# 一時認証情報を環境変数に設定
export AWS_ACCESS_KEY_ID=<一時キー>
export AWS_SECRET_ACCESS_KEY=<一時シークレット>
export AWS_SESSION_TOKEN=<セッショントークン>
```

#### Athenaコンソールでのアクセス
1. AWSコンソールにログイン
2. 右上のユーザー名をクリック → "Switch Role"を選択
3. ワークグループユーザーロールに切り替え
4. Athenaコンソールを開く
5. 指定されたワークグループを選択

## 環境分離の確認方法

### 1. データベース一覧の確認
正常に実装されている場合、以下のような動作になります：

```sql
-- ✅ 成功: 自環境のデータベースは表示される
SHOW DATABASES;
-- 結果: rcs_stg_web_logs のみ表示

-- ❌ 失敗: 他環境のテーブルへのアクセスは拒否される
SELECT * FROM rcs_prd_web_logs.django_web LIMIT 1;
-- エラー: Access Denied
```

### 2. ワークグループアクセスの確認
```bash
# 現在のワークグループを確認
aws athena get-work-group --work-group rcs-stg-analytics

# 他のワークグループアクセスを試行（失敗するはず）
aws athena get-work-group --work-group rcs-prd-analytics
# エラー: AccessDenied
```

## トラブルシューティング

### よくある問題と解決方法

#### 1. パーティションエラー（COLUMN_NOT_FOUND: Column 'partition_0' cannot be resolved）
**原因**: S3にデータは存在するが、Glue Catalogにパーティション情報が登録されていない
**解決方法**:
```sql
-- Step 1: パーティションの確認
SHOW PARTITIONS rcs_stg_web_logs."rcs-stg-django_web" LIMIT 5;
SHOW PARTITIONS rcs_stg_web_logs."rcs-stg-nginx_web" LIMIT 5;
SHOW PARTITIONS rcs_stg_web_logs."rcs-stg-error" LIMIT 5;

-- Step 2: パーティションの修復（各コマンドを個別に実行）
MSCK REPAIR TABLE rcs_stg_web_logs."rcs-stg-django_web";
MSCK REPAIR TABLE rcs_stg_web_logs."rcs-stg-nginx_web";
MSCK REPAIR TABLE rcs_stg_web_logs."rcs-stg-error";

-- Step 3: 修復後の確認
SHOW PARTITIONS rcs_stg_web_logs."rcs-stg-django_web" LIMIT 10;
SHOW PARTITIONS rcs_stg_web_logs."rcs-stg-nginx_web" LIMIT 10;
SHOW PARTITIONS rcs_stg_web_logs."rcs-stg-error" LIMIT 10;
```

**参考**: より詳細な手順は `templates/basic_analysis/partition_repair.sql` を参照

#### 2. 他環境のテーブルが見える場合
**原因**: IAMポリシーのDeny条件が正しく動作していない
**解決方法**:
```bash
# IAMポリシーを確認
aws iam get-role-policy \
  --role-name $(terraform output -raw workgroup_user_role_name) \
  --policy-name $(terraform output -raw workgroup_user_role_name)-policy

# Terraformを再適用
terraform apply -target=aws_iam_role_policy.athena_workgroup_user_policy
```

#### 3. アクセス拒否エラーが発生する場合
**原因**: 必要な権限が不足している
**解決方法**:
```bash
# ユーザーの権限を確認
aws iam list-attached-user-policies --user-name <ユーザー名>
aws iam list-user-policies --user-name <ユーザー名>

# ロールの引き受け権限を確認
aws sts get-caller-identity
```

#### 4. クエリ結果が保存できない場合
**原因**: S3へのアクセス権限が不足
**解決方法**:
```bash
# S3バケットポリシーを確認
aws s3api get-bucket-policy --bucket $(terraform output -raw logs_bucket_name)

# 必要に応じてS3アクセス権限を追加
```

## セキュリティベストプラクティス

### 1. 最小権限の原則
- ユーザーには必要最小限の権限のみ付与
- 定期的な権限の見直しとクリーンアップ

### 2. 監査とログ
```bash
# CloudTrailでのAthenaアクセスログ確認
aws logs filter-log-events \
  --log-group-name CloudTrail \
  --filter-pattern "athena"
```

### 3. 定期的な権限確認
```bash
# 月次でユーザー権限を確認
aws iam list-users --query 'Users[*].[UserName,CreateDate]' --output table
```

## まとめ

この実装により、以下が実現されます：

1. **環境分離**: ステージング環境のワークグループからプロダクション環境のテーブルにアクセス不可
2. **最小権限**: ユーザーは必要最小限のリソースのみアクセス可能
3. **監査性**: すべてのアクセスがIAMポリシーにより制御・記録される
4. **スケーラビリティ**: 新しい環境やプロジェクトを同様の方式で追加可能

環境分離が正しく動作しない場合は、上記のトラブルシューティングセクションを参照してください。
