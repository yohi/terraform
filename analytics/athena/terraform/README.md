# Athena Analytics Infrastructure

AWS Athena分析環境を自動構築するTerraform構成です。S3データからGlue Crawlerによる自動スキーマ検出、Athenaでのクエリ実行、QuickSightでの可視化までの完全なデータ分析パイプラインを提供します。

## 📋 構成概要

このTerraform構成は以下のAWSリソースを作成します：

1. **AWS Glue** - データカタログデータベースとCrawler
2. **Amazon S3** - データストレージとクエリ結果保存
3. **Amazon Athena** - データクエリとワークグループ
4. **IAM** - 各サービス間の権限管理
5. **QuickSight連携** - データ可視化用の権限設定（オプション）

## 🔒 セキュリティ機能

### AWS Account検証機能（Terraformネイティブ）
誤ったAWSアカウントでの実行を防ぐため、Terraformネイティブの検証を使用：

```hcl
# 特定のAWSアカウントIDでの実行を強制
expected_aws_account_id = "123456789012"
```

**CI/CD環境での使用例**:
```bash
# 環境変数を使用
export TF_VAR_expected_aws_account_id="123456789012"
terraform plan
terraform apply
```

**動作**:
1. 現在のAWSアカウントIDを取得
2. `expected_aws_account_id`が設定されている場合、値を照合
3. 不一致の場合はTerraformがエラーで停止
4. 空文字列の場合はアカウント検証をスキップ

### S3バケット検証機能（Terraformネイティブ）
S3バケットの存在確認と作成ポリシーを制御：

```hcl
# 基本設定
auto_create_bucket = false           # バケット自動作成を無効化
require_bucket_exists = false        # 既存バケットを要求しない
skip_bucket_validation = false       # バケット検証を実行

# CI/CD環境向け設定例
require_bucket_exists = true         # 既存バケットを要求
skip_bucket_validation = false       # バケット検証を実行
```

**検証パターン**:
- `require_bucket_exists = true` → バケットが存在しない場合はエラー
- `require_bucket_exists = false` + `auto_create_bucket = true` → バケットを自動作成
- `skip_bucket_validation = true` → バケット検証をスキップ（外部でバケット管理する場合）

### 従来のbashスクリプト（非推奨）
⚠️ **非推奨**: 以下のbashスクリプトはSaaS/CI環境では動作しない可能性があります：

```bash
# 従来の方法（CI/CD環境では使用しないでください）
./plan_with_confirmation.sh
./apply_with_confirmation.sh
```

**推奨**: 上記のTerraformネイティブ検証を使用してください。

## 🏗️ アーキテクチャ

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   S3 Bucket     │    │   AWS Glue      │    │     Athena      │
│                 │    │                 │    │                 │
│ ├─ data/        │◄───┤ ├─ Database     │◄───┤ ├─ Workgroup    │
│ │  ├─ type1/    │    │ ├─ Crawlers     │    │ ├─ Database     │
│ │  ├─ type2/    │    │ └─ Tables       │    │ ├─ Tables       │
│ │  └─ type3/    │    │                 │    │ └─ Views        │
│ └─ athena-      │    │                 │    │                 │
│    results/     │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                      │
                                                      ▼
                                            ┌─────────────────┐
                                            │   QuickSight    │
                                            │                 │
                                            │ ├─ Data Source  │
                                            │ ├─ Datasets     │
                                            │ └─ Dashboards   │
                                            └─────────────────┘
```

## 📦 作成されるリソース

### AWS Glue
- **Catalog Database**: データメタデータの管理
- **Crawlers**: 各ログタイプ用の自動スキーマ検出
- **IAM Role**: Crawler実行用の権限

### Amazon S3
- **Bucket**: データストレージ（オプション自動作成）
- **Encryption**: AES256暗号化
- **Public Access Block**: セキュリティ設定
- **Versioning**: データ保護

### Amazon Athena
- **Workgroup**: クエリ実行環境
- **Database**: データベース
- **Named Queries**: テーブル作成、パーティション追加、ビュー作成用

### IAM
- **Athena Role**: S3とGlueへのアクセス権限
- **Glue Crawler Role**: S3データ読み取り権限
- **QuickSight Role**: Athena/Glue/S3アクセス権限（オプション）

## 🚀 使用方法

### 1. 前提条件

- AWS CLI設定済み
- Terraform v1.0以上
- 以下のAWS権限：
  - S3: バケット作成・読み書き
  - Glue: データベース・クローラー作成
  - Athena: ワークグループ・データベース作成
  - IAM: ロール・ポリシー作成
  - QuickSight: サービスロール作成（オプション）

### 2. 設定ファイル

```bash
# 設定ファイルを作成
cp terraform.tfvars.example terraform.tfvars
```

#### 必須変数

```hcl
# プロジェクト識別子
project           = "myproject"        # プロジェクト名
env              = "dev"               # 環境名
app              = "analytics"         # アプリケーション名

# S3設定
logs_bucket_name = "myproject-analytics-data"  # データ保存バケット名
logs_s3_prefix   = "data/logs"                 # バケット内のデータパス
```

#### オプション変数

```hcl
# バケット自動作成
auto_create_bucket = true              # 存在しない場合の自動作成

# 検証設定（CI/CD環境向け）
expected_aws_account_id = "123456789012"  # AWSアカウントID検証
require_bucket_exists = false          # 既存バケットを要求
skip_bucket_validation = false         # バケット検証をスキップ

# QuickSight連携
enable_quicksight = true               # QuickSight用IAMロール作成

# Athenaデータベース名（デフォルト：{project}_{env}_{app}_logs形式で環境と案件を明確化）
athena_database_name = "rcs_prd_web_logs"

# AWSリージョン
aws_region = "ap-northeast-1"

# タグ
tags = {
  Owner       = "data-team"
  Environment = "development"
}
```

### 3. ログタイプ設定

デフォルトで以下のログタイプが設定されています：

```hcl
log_types = {
  django_web = {
    table_name_suffix = "django_web"
    description       = "Django web application logs"
    schema = {
      date               = { type = "string", description = "Log timestamp" }
      source             = { type = "string", description = "Log source (stdout/stderr)" }
      log                = { type = "string", description = "Log message content" }
      container_id       = { type = "string", description = "Container ID" }
      container_name     = { type = "string", description = "Container name" }
      ec2_instance_id    = { type = "string", description = "EC2 instance ID" }
      ecs_cluster        = { type = "string", description = "ECS cluster name" }
      ecs_task_arn       = { type = "string", description = "ECS task ARN" }
      ecs_task_definition = { type = "string", description = "ECS task definition" }
    }
  }
  nginx_web = { /* 同様の構造 */ }
  error     = { /* 同様の構造 */ }
}
```

### 4. デプロイ

```bash
# 初期化
terraform init

# 計画の実行
terraform plan

# 適用の実行
terraform apply
```

### 5. CI/CD環境での使用

#### GitHub Actions / GitLab CI例

```yaml
env:
  TF_VAR_expected_aws_account_id: "123456789012"
  TF_VAR_require_bucket_exists: "true"
  TF_VAR_skip_bucket_validation: "false"

steps:
  - name: Terraform Plan
    run: terraform plan

  - name: Terraform Apply
    run: terraform apply -auto-approve
```

#### Jenkins例

```groovy
environment {
    TF_VAR_expected_aws_account_id = "123456789012"
    TF_VAR_require_bucket_exists = "true"
}

stage('Deploy') {
    steps {
        sh 'terraform init'
        sh 'terraform plan'
        sh 'terraform apply -auto-approve'
    }
}
```

#### 推奨CI/CD設定

```hcl
# terraform.tfvars (CI/CD環境用)
expected_aws_account_id = "123456789012"    # 対象アカウントID
require_bucket_exists = true               # バケットの事前作成を要求
skip_bucket_validation = false             # バケット検証を実行
auto_create_bucket = false                 # 自動作成を無効化
```

## 📁 データ構造

S3バケット内のデータ構造：

```
s3://myproject-analytics-data/
├── data/logs/                    # logs_s3_prefix
│   ├── django_web/              # ログタイプ別フォルダ
│   │   ├── year=2024/month=01/day=01/
│   │   │   └── data.csv
│   │   └── year=2024/month=01/day=02/
│   │       └── data.csv
│   ├── nginx_web/
│   │   └── year=2024/month=01/day=01/
│   │       └── access.csv
│   └── error/
│       └── year=2024/month=01/day=01/
│           └── error.csv
└── athena-query-results/         # Athenaクエリ結果
    └── 2024/01/01/
        └── query-results.csv
```

## 🔄 運用フロー

### 1. データアップロード

```bash
# CSVファイルをS3にアップロード
aws s3 cp logs.csv s3://myproject-analytics-data/data/logs/django_web/year=2024/month=01/day=01/
```

### 2. Crawler実行

```bash
# 作成されたCrawlerを実行
aws glue start-crawler --name myproject-dev-django_web-crawler

# 実行状況確認
aws glue get-crawler --name myproject-dev-django_web-crawler
```

### 3. テーブル確認

Athenaコンソールで以下を実行：

```sql
-- データベース内のテーブル一覧
SHOW TABLES IN myproject_dev_logs;

-- テーブル構造確認
DESCRIBE myproject_dev_logs.myproject_dev_django_web;

-- データ確認
SELECT * FROM myproject_dev_logs.myproject_dev_django_web LIMIT 10;
```

### 4. ビュー作成

Athenaの「Saved queries」から対応するビュー作成クエリを実行：

```sql
-- 例：django_webのビュー作成
CREATE OR REPLACE VIEW myproject_dev_django_web_view AS
SELECT
    parsed_timestamp,
    log_date,
    log_hour,
    log_message,
    detected_log_level
FROM myproject_dev_logs.myproject_dev_django_web;
```

## 📊 分析クエリ例

### 基本的な分析

```sql
-- 日別ログ件数
SELECT
    log_date,
    COUNT(*) as log_count
FROM myproject_dev_logs.myproject_dev_django_web_view
WHERE log_date >= current_date - interval '7' day
GROUP BY log_date
ORDER BY log_date;

-- エラーレベル別集計
SELECT
    detected_log_level,
    COUNT(*) as count
FROM myproject_dev_logs.myproject_dev_error_view
WHERE log_date = current_date
GROUP BY detected_log_level;

-- 時間別アクセス分析
SELECT
    log_hour,
    COUNT(*) as access_count
FROM myproject_dev_logs.myproject_dev_nginx_web_view
WHERE log_date = current_date
GROUP BY log_hour
ORDER BY log_hour;
```

### 高度な分析

```sql
-- コンテナ別エラー率
SELECT
    container_name,
    COUNT(*) as total_logs,
    SUM(CASE WHEN detected_log_level = 'error' THEN 1 ELSE 0 END) as error_logs,
    CAST(SUM(CASE WHEN detected_log_level = 'error' THEN 1 ELSE 0 END) AS DOUBLE) / COUNT(*) * 100 as error_rate
FROM myproject_dev_logs.myproject_dev_django_web_view
WHERE log_date >= current_date - interval '1' day
GROUP BY container_name
HAVING COUNT(*) > 100
ORDER BY error_rate DESC;
```

## 🔐 セキュリティ設定

### 暗号化
- **S3**: AES256 (SSE-S3)
- **Athena**: SSE_S3

### IAM権限
- **最小権限の原則**: 各ロールは必要最小限の権限のみ
- **リソース制限**: 特定のS3バケットとGlueデータベースのみアクセス可能
- **条件付きアクセス**: リージョン制限などの条件を設定

### ネットワーク
- **パブリックアクセスブロック**: S3バケットへの意図しないパブリックアクセスを防止

## 🛠️ カスタマイズ

### 新しいログタイプの追加

```hcl
# terraform.tfvarsに追加
log_types = {
  # 既存のタイプ...

  api_logs = {
    table_name_suffix = "api_logs"
    description       = "API access logs"
    schema = {
      timestamp    = { type = "string", description = "Request timestamp" }
      method       = { type = "string", description = "HTTP method" }
      path         = { type = "string", description = "Request path" }
      status_code  = { type = "int", description = "HTTP status code" }
      response_time = { type = "double", description = "Response time in ms" }
    }
  }
}
```

### ビューのカスタマイズ

`templates/create_view.sql`を編集して、ビジネス要件に合わせた分析項目を追加。

### パーティション戦略

```sql
-- 年月日パーティション
CREATE TABLE my_table (
  data string,
  log_message string
)
PARTITIONED BY (
  year string,
  month string,
  day string
)
```

## 📈 監視とメンテナンス

### CloudWatch監視

```bash
# Crawler実行状況の監視
aws logs describe-log-groups --log-group-name-prefix "/aws-glue/crawlers"

# Athenaクエリメトリクス
aws cloudwatch get-metric-statistics \
  --namespace AWS/Athena \
  --metric-name QueryExecutionTime \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-02T00:00:00Z \
  --period 3600 \
  --statistics Average
```

### 自動化

```bash
# Crawler定期実行（CloudWatch Events）
aws events put-rule \
  --name daily-crawler \
  --schedule-expression "cron(0 2 * * ? *)"

aws events put-targets \
  --rule daily-crawler \
  --targets "Id"="1","Arn"="arn:aws:glue:region:account:crawler/crawler-name"
```

### コスト最適化

1. **パーティション戦略**: 日付ベースのパーティションでスキャン量を削減
2. **データ圧縮**: Parquet形式への変換でストレージコストを削減
3. **ライフサイクル管理**: 古いデータのIA/Glacierへの移行
4. **クエリ最適化**: WHEREクラウスでのパーティション絞り込み

## 🔧 トラブルシューティング

### よくある問題

1. **Crawlerがテーブルを作成しない**
   ```bash
   # データの存在確認
   aws s3 ls s3://bucket/path/ --recursive

   # IAM権限確認
   aws iam simulate-principal-policy \
     --policy-source-arn arn:aws:iam::account:role/glue-role \
     --action-names s3:GetObject \
     --resource-arns arn:aws:s3:::bucket/path/*
   ```

2. **Athenaクエリが失敗する**
   ```sql
   -- データ型確認
   DESCRIBE table_name;

   -- パーティション確認
   SHOW PARTITIONS table_name;
   ```

3. **権限エラー**
   ```bash
   # CloudTrailでAPI呼び出しを確認
   aws logs filter-log-events \
     --log-group-name CloudTrail/AthenaAccess \
     --start-time 1640995200000
   ```

## 📚 出力情報

Terraform適用後、以下の情報が出力されます：

- **接続情報**: AWS アカウント、リージョン、リソース名
- **S3ロケーション**: データ保存場所とクエリ結果保存場所
- **Glue情報**: データベース名、Crawler名
- **Athena情報**: ワークグループ名、名前付きクエリ
- **セキュリティ情報**: IAMロールARN、暗号化設定
- **実行ガイド**: 次に実行すべき手順

## 🤝 サポート

技術的な問題やカスタマイズの相談については、プロジェクトのIssueトラッカーまでお知らせください。
