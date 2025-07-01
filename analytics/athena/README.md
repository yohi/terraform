# Athena Analytics for Multiple Firelens Log Types

このTerraform構成は、FirelensでS3に保存されている複数タイプのログ（Django Web、Nginx Web、Error など）をAthenaで分析できるようにするものです。

## 🆕 新機能・改善点

- **強化されたセキュリティ**: S3バケットのパブリックアクセスブロック、IAMポリシーの最小権限原則
- **改善されたエラーハンドリング**: スクリプトの堅牢性向上、タイムアウト処理
- **ログ記録**: AWS確認プロセスのログ記録機能
- **入力バリデーション**: 変数入力時の詳細なバリデーション
- **カラー出力**: 見やすいコンソール出力
- **ヘルプ機能**: 各スクリプトに詳細なヘルプオプション追加
- **🔄 Glue Crawler自動実行**: スケジュール機能による自動的なスキーマ検出とテーブル作成
  - デフォルト: 毎日午前3時に自動実行
  - カスタマイズ可能なスケジュール設定（cron/rate形式）
  - 手動実行からの完全移行でメンテナンス負荷を軽減

## 構成

### 作成されるリソース

- **S3バケット**: Athenaクエリ結果保存用 (`{project}-{env}-athena-results`)
  - バージョニング有効
  - SSE-S3暗号化
  - パブリックアクセス完全ブロック
  - 30日間のライフサイクル設定
- **Athenaワークグループ**: `{project}-{env}-analytics`
  - クエリ結果の暗号化
  - CloudWatchメトリクス有効
- **Athenaデータベース**: `{project}_{env}_logs`
- **Athenaテーブル**: 各ログタイプごとに作成（パーティション射影有効）
- **IAMロール**: 最小権限原則に基づくAthena実行ロール
- **Glue Crawler**: 各ログタイプごとに自動スキーマ検出（スケジュール実行対応）
  - デフォルト実行スケジュール: 毎日午前3時
  - 設定可能なスケジュール: cron/rate形式でカスタマイズ可能
  - 自動パーティション検出とテーブル更新
- **Athena名前付きクエリ**:
  - 各ログタイプのテーブル作成クエリ
  - 各ログタイプのパーティション追加クエリ
  - 各ログタイプの専用サンプルクエリ（パフォーマンス最適化済み）
  - 全テーブル横断の概要クエリ

### 対応ログタイプ

デフォルトで以下のログタイプに対応しています：

1. **django_web**: Django Webアプリケーションログ
2. **nginx_web**: Nginx Webサーバーログ
3. **error**: エラーログ

### ディレクトリ構造

```
analytics/athena/
├── terraform/
│   ├── main.tf                      # メインTerraform設定
│   ├── variables.tf                 # 変数定義
│   ├── outputs.tf                   # 出力値
│   ├── versions.tf                  # プロバイダバージョン
│   ├── terraform.tfvars.example     # 設定例
│   ├── aws_account_check.sh         # AWS確認（外部データ用）
│   ├── plan_with_confirmation.sh    # 確認付きplan実行
│   └── apply_with_confirmation.sh   # 確認付きapply実行
├── templates/
│   ├── create_table.sql             # テーブル作成SQL
│   ├── add_partitions.sql           # パーティション追加SQL
│   ├── sample_queries_django_web.sql
│   ├── sample_queries_nginx_web.sql
│   ├── sample_queries_error.sql
│   ├── sample_queries.sql           # 汎用サンプルクエリ
│   └── all_tables_overview.sql      # 全テーブル概要クエリ
└── README.md
```

## セットアップ手順

### 0. 前提条件の確認

必要なツールがインストールされていることを確認してください：

```bash
# 必要なツール
aws --version      # AWS CLI
jq --version       # JSON processor
terraform version  # Terraform
```

### 1. AWS アカウント確認（重要）

⚠️ **重要**: Terraformを実行する前に、正しいAWSアカウントに接続していることを確認してください。

#### **推奨方法：確認付きTerraformスクリプト**

```bash
# 現在のディレクトリに移動
cd analytics/athena/terraform

# Plan実行前にアカウント情報を確認（推奨）
./plan_with_confirmation.sh

# Apply実行前にアカウント情報を確認（推奨）
./apply_with_confirmation.sh
```

**これらのスクリプトの機能：**
- 現在のAWS認証情報を表示
- Y/N で確認を求める
- 変数入力の順序を最適化（project → env → logs_s3_prefix）
- 入力バリデーション
- カラー出力による視認性向上
- エラーハンドリング強化

#### **スクリプトオプション**

```bash
# ヘルプ表示
./plan_with_confirmation.sh --help
./apply_with_confirmation.sh --help

# AWS確認をスキップ（注意して使用）
./plan_with_confirmation.sh --yes

# Terraform apply確認もスキップ（非常に注意）
./apply_with_confirmation.sh --yes --auto-approve

# 保存済みプランファイルを使用
./apply_with_confirmation.sh -- plan.out
```

#### **その他の確認方法**

```bash
# スクリプトでアカウント情報を確認
../../check_aws_account.sh

# 環境変数で確認をスキップ
export TERRAFORM_AWS_ACCOUNT_CONFIRMED=true

# 直接AWS CLIで確認
aws sts get-caller-identity
```

### 2. 設定ファイルの準備

```bash
cd analytics/athena/terraform
cp terraform.tfvars.example terraform.tfvars
```

### 3. 変数設定

#### 🔧 確認付きスクリプト使用（推奨）

確認付きスクリプトを使用すると、以下の順序で変数を手動入力できます：

```bash
# Plan実行（AWS確認 + 期待する順序での変数入力）
./plan_with_confirmation.sh

# Apply実行（AWS確認 + 期待する順序での変数入力）
./apply_with_confirmation.sh
```

**入力順序:**
1. **project** - プロジェクト名（例: rcs, myapp）
2. **env** - 環境名（例: prd, stg, dev）
3. **logs_s3_prefix** - S3ログプレフィックス（例: firelens/firelens/fluent-bit-logs）

**スクリプトの特徴:**
- 各変数に対してAWS認証情報の確認
- 入力例を表示
- 入力バリデーション（空値、不正文字チェック）
- 入力完了後に確認表示

#### **S3プレフィックス設定例**

ログが保存されているS3パスの、ログタイプ（`django_web`等）の直前までを指定してください：

```hcl
# 1. Firelens標準パターン
logs_s3_prefix = "firelens/firelens/fluent-bit-logs"
# → s3://bucket/firelens/firelens/fluent-bit-logs/{log_type}/yyyy/mm/dd/hh/

# 2. カスタムパターン1
logs_s3_prefix = "app-logs/production"
# → s3://bucket/app-logs/production/{log_type}/yyyy/mm/dd/hh/

# 3. カスタムパターン2
logs_s3_prefix = "logs/containers/ecs"
# → s3://bucket/logs/containers/ecs/{log_type}/yyyy/mm/dd/hh/

# 4. シンプルパターン
logs_s3_prefix = "logs"
# → s3://bucket/logs/{log_type}/yyyy/mm/dd/hh/
```

### 4. Terraformの実行

#### 🎯 推奨方法（AWS確認 + 期待する順序での入力）

```bash
# 初期化
terraform init

# Plan実行（AWS認証確認 + project→env→logs_s3_prefix順での入力）
./plan_with_confirmation.sh

# Apply実行（AWS認証確認 + 変数入力）
./apply_with_confirmation.sh
```

#### **直接実行時の制限と回避策**

**`terraform plan`を直接実行する場合の制限:**
- Terraformの仕様により、変数は常にアルファベット順で入力を求められます
- 順序: `env` → `logs_s3_prefix` → `project`
- AWS認証情報の確認は行われません

**回避策:**
```bash
# 1. 確認付きスクリプトを使用（推奨）
./plan_with_confirmation.sh

# 2. または、変数を事前に指定
terraform plan -var="project=rcs" -var="env=stg" -var="logs_s3_prefix=s3-prefix"

# 3. terraform.tfvarsファイルを編集して使用
terraform plan
```

### 5. ログタイプのカスタマイズ（オプション）

`terraform.tfvars` で `log_types` 変数を設定してカスタマイズできます：

```hcl
log_types = {
  django_web = {
    table_name_suffix = "django_web"
    description       = "Django web application logs"
    schema = {
      date = {
        type        = "string"
        description = "Log timestamp"
      }
      source = {
        type        = "string"
        description = "Log source (stdout/stderr)"
      }
      log = {
        type        = "string"
        description = "Log message content"
      }
      # ... 他のフィールド
    }
  }
  # 新しいログタイプを追加
  custom_app = {
    table_name_suffix = "custom_app"
    description       = "Custom application logs"
    schema = {
      timestamp = {
        type        = "string"
        description = "Application timestamp"
      }
      level = {
        type        = "string"
        description = "Log level"
      }
      message = {
        type        = "string"
        description = "Log message"
      }
    }
  }
}
```

## 🔄 Glue Crawler自動実行設定

### スケジュール機能の概要

Glue Crawlerは新しいログファイルが追加されるタイミングで自動実行され、テーブルスキーマの更新とパーティションの検出を行います。

### 設定オプション

#### 基本設定

```hcl
# terraform.tfvars
enable_crawler_schedule = true                   # 自動実行を有効化
crawler_schedule_expression = "cron(0 3 * * ? *)" # 毎日午前3時に実行
crawler_max_concurrent_runs = 1                   # 同時実行数制限
```

#### スケジュール表現の例

**推奨パターン:**
```hcl
# 毎日午前3時（アクセスが少ない時間帯）
crawler_schedule_expression = "cron(0 3 * * ? *)"

# 営業時間外（平日午後6時と土日午前10時）
crawler_schedule_expression = "cron(0 18 ? * MON-FRI *)"
```

**頻繁な更新が必要な場合:**
```hcl
# 4時間ごと
crawler_schedule_expression = "rate(4 hours)"

# 2時間ごと
crawler_schedule_expression = "rate(2 hours)"

# 毎時00分
crawler_schedule_expression = "cron(0 * * * ? *)"
```

**特定の時間帯:**
```hcl
# 午前6時と午後6時
crawler_schedule_expression = "cron(0 6,18 * * ? *)"

# 月曜日から金曜日の午前2時
crawler_schedule_expression = "cron(0 2 ? * MON-FRI *)"

# 月初の午前1時
crawler_schedule_expression = "cron(0 1 1 * ? *)"
```

### cron形式の詳細

AWS Glue Crawlerで使用可能なcron形式：

```
cron(分 時 日 月 曜日 年)
```

| フィールド | 値            | ワイルドカード |
| ---------- | ------------- | -------------- |
| 分         | 0-59          | , - * /        |
| 時         | 0-23          | , - * /        |
| 日         | 1-31          | , - * ? / L W  |
| 月         | 1-12          | , - * /        |
| 曜日       | 1-7 (SUN-SAT) | , - * ? L #    |
| 年         | 1970-2199     | , - * /        |

**重要:** 日と曜日の両方を指定することはできません。片方を `?` にする必要があります。

### rate形式の詳細

```
rate(値 単位)
```

- **単位**: `minute`, `minutes`, `hour`, `hours`, `day`, `days`
- **値**: 正の整数

**例:**
```hcl
rate(30 minutes)  # 30分ごと
rate(1 hour)      # 1時間ごと
rate(2 hours)     # 2時間ごと
rate(1 day)       # 1日ごと
```

### 運用上の考慮事項

#### スケジュール選択の指針

1. **ログ生成頻度**: アプリケーションのログ生成パターンに合わせる
2. **クエリ頻度**: 分析の頻度に応じて最適化
3. **コスト効率**: 過度な実行を避けて AWS 利用料金を抑制
4. **システム負荷**: ピーク時間帯を避けた実行タイミング

#### 推奨設定パターン

**本番環境（高可用性）:**
```hcl
enable_crawler_schedule = true
crawler_schedule_expression = "cron(0 3 * * ? *)"  # 毎日午前3時
```

**開発・テスト環境（コスト重視）:**
```hcl
enable_crawler_schedule = true
crawler_schedule_expression = "cron(0 6 * * MON-FRI *)"  # 平日午前6時のみ
```

**リアルタイム分析（高頻度）:**
```hcl
enable_crawler_schedule = true
crawler_schedule_expression = "rate(2 hours)"  # 2時間ごと
```

#### 手動実行への切り替え

緊急時やメンテナンス時は手動実行に切り替え可能：

```hcl
# terraform.tfvars
enable_crawler_schedule = false  # スケジュール無効化
```

```bash
# 手動実行
aws glue start-crawler --name your-crawler-name --region ap-northeast-1
```

### 監視とアラート

#### CloudWatch メトリクス

Glue Crawlerの実行状況は以下のメトリクスで監視できます：

- `glue.driver.aggregate.numCompletedTasks`
- `glue.driver.aggregate.elapsedTime`
- `glue.ALL.s3.filesystem.read_bytes`

#### 実行状況の確認

```bash
# 最新の実行状況を確認
aws glue get-crawler --name rcs-stg-django_web-crawler --region ap-northeast-1

# 実行履歴を確認
aws glue get-crawler-metrics --crawler-name-list rcs-stg-django_web-crawler --region ap-northeast-1
```

## セキュリティとベストプラクティス

### セキュリティ機能

- **S3バケットのパブリックアクセス完全ブロック**
- **IAMロールの最小権限原則**
- **S3暗号化（SSE-S3）**
- **リージョン制限付きAssumeRole**
- **Glueカタログの明示的なリソース指定**

### パフォーマンス最適化

- **パーティション射影**: 自動パーティション検出
- **クエリ結果の階層化された格納**
- **効率的なS3ライフサイクル設定**
- **最適化されたサンプルクエリ**

### ログ記録

AWS確認スクリプトは以下のログを記録します：
```bash
# ログファイル確認
tail -f analytics/athena/terraform/aws_account_check.log
```

## トラブルシューティング

### よくある問題

1. **AWS CLI未設定**
   ```bash
   aws configure
   # または
   export AWS_PROFILE=your-profile
   ```

2. **jq未インストール**
   ```bash
   # Ubuntu/Debian
   sudo apt-get install jq

   # macOS
   brew install jq
   ```

3. **Terraform初期化が必要**
   ```bash
   terraform init
   ```

4. **権限エラー**
   - IAMユーザーにGlue、S3、Athenaの権限が必要です
   - AWS Organizationsへのアクセス権限（アカウント名取得用、オプション）

### デバッグ

```bash
# Terraform詳細ログ
export TF_LOG=DEBUG
terraform plan

# AWS CLI詳細ログ
aws sts get-caller-identity --debug

# スクリプトデバッグ
bash -x ./plan_with_confirmation.sh
```

## クエリ例

### 基本的なログ分析

```sql
-- 時間別ログ数（必ずパーティションを指定）
SELECT
    year, month, day, hour,
    COUNT(*) as log_count,
    COUNT(DISTINCT container_id) as unique_containers
FROM your_project_env_logs.your_project_env_django_web
WHERE year = '2025'
    AND month = '01'
    AND day = '15'
GROUP BY year, month, day, hour
ORDER BY year, month, day, hour;
```

### エラー分析

```sql
-- エラーログの識別
SELECT
    date,
    container_name,
    log
FROM your_project_env_logs.your_project_env_error
WHERE year = '2025'
    AND month = '01'
    AND day = '15'
    AND (
        LOWER(log) LIKE '%error%'
        OR LOWER(log) LIKE '%exception%'
        OR LOWER(log) LIKE '%critical%'
    )
ORDER BY date DESC
LIMIT 100;
```

## リソース削除

```bash
# リソースを削除する場合
./apply_with_confirmation.sh -- -destroy

# または確認付きで削除
terraform destroy
```

## 参考リンク

- [Amazon Athena Documentation](https://docs.aws.amazon.com/athena/)
- [Athena Partition Projection](https://docs.aws.amazon.com/athena/latest/ug/partition-projection.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
