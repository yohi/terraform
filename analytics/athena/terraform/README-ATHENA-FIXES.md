# Athena テーブル修正について

## 修正内容

このフォルダ内のTerraform設定と関連テンプレートに対して、Athenaクエリが適切に実行できるよう以下の修正を行いました。

### 1. JSONSerDe設定の修正

**問題**: テーブル作成SQLでJSONファイルを適切に読み取るためのSerDe設定が不適切でした。

**修正内容**:
- `create_table.sql`テンプレートで、適切なJSON SerDe設定を追加
- `ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'`を追加
- `WITH SERDEPROPERTIES`でJSON処理のオプション設定

```sql
ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
WITH SERDEPROPERTIES (
  'serialization.format' = '1',
  'ignore.malformed.json' = 'TRUE',
  'dots.in.keys' = 'FALSE',
  'case.insensitive' = 'TRUE',
  'mapping' = 'TRUE'
)
```

### 2. パーティション投影の修正

**問題**: S3ロケーションテンプレートのパス設定が不適切でした。

**修正内容**:
- パーティション投影のS3パステンプレートを修正
- `year=YYYY/month=MM/day=DD/hour=HH`形式に変更

```sql
'projection.location.template' = '${s3_location}year=${year}/month=${month}/day=${day}/hour=${hour}/',
'storage.location.template' = '${s3_location}year=${year}/month=${month}/day=${day}/hour=${hour}/'
```

### 3. サンプルクエリの修正

**問題**: すべてのサンプルクエリでハードコードされた日付（'2025', '06', '25'）が使用されていました。

**修正内容**:
- 動的な日付を使用するよう修正
- 現在の日付と時刻に基づいたクエリに変更
- 過去3時間のデータを取得するフィルターを追加

**修正前**:
```sql
WHERE year = '2025' AND month = '06' AND day = '25'
```

**修正後**:
```sql
WHERE
    year = CAST(year(current_date) AS varchar)
    AND month = CAST(month(current_date) AS varchar)
    AND day = CAST(day(current_date) AS varchar)
    AND CAST(hour AS integer) >= CAST(hour(current_timestamp) AS integer) - 3
```

## S3データ構造の要件

修正されたテーブル設定は、以下のS3パーティション構造を前提としています：

```
s3://your-logs-bucket/logs-prefix/log-type/year=YYYY/month=MM/day=DD/hour=HH/
```

例：
```
s3://my-app-logs/firelens/fluent-bit-logs/django_web/year=2025/month=01/day=15/hour=14/
s3://my-app-logs/firelens/fluent-bit-logs/nginx_web/year=2025/month=01/day=15/hour=14/
```

### データファイル形式

- **ファイル形式**: JSON行形式（JSONL）
- **ファイル拡張子**: `.json` または拡張子なし
- **圧縮**: 未圧縮（圧縮が必要な場合は追加設定が必要）

## 使用方法

### 1. Terraform Apply

```bash
cd analytics/athena/terraform
terraform init
terraform plan
terraform apply
```

### 2. テーブル作成の確認

Terraform Applyの実行により、以下が作成されます：
- AWS Glue Database
- AWS Glue Crawler（各ログタイプ用）
- Athena Workgroup
- Athena Named Queries（テーブル作成、サンプルクエリ等）

### 3. Athenaコンソールでのクエリ実行

1. AWS Athenaコンソールにアクセス
2. 作成されたWorkgroupを選択
3. 「Saved queries」から任意のクエリを選択して実行

### 4. Crawlerの実行

S3にデータが存在する場合、以下のいずれかの方法でテーブルスキーマを更新：

**手動実行**:
```bash
aws glue start-crawler --name YOUR_PROJECT-ENV-LOG_TYPE-crawler
```

**自動実行**:
- `enable_crawler_schedule = true`を設定している場合、定期的に実行されます

## トラブルシューティング

### 1. テーブルが見つからない

```sql
SHOW TABLES IN your_database_name;
```

### 2. パーティションが見つからない

```sql
SHOW PARTITIONS your_database_name.your_table_name;
```

### 3. JSON解析エラー

- S3のデータファイルがJSON形式か確認
- 改行区切りJSON（JSONL）形式になっているか確認
- ファイルが破損していないか確認

### 4. パーティション投影が動作しない

- S3パス構造が設定と一致しているか確認
- パーティション投影の日付範囲が適切か確認

### 5. "Queries of this type are not supported" エラー

**問題**: パーティション投影を使用している場合、パーティション列で`current_date`や`current_timestamp`などの動的関数を直接使用するとこのエラーが発生します。

**解決方法**:

#### 方法1: 手動で日付を指定
```sql
-- 実行前に今日の日付を確認
SELECT
  CAST(year(current_date) AS varchar) as current_year,
  CAST(month(current_date) AS varchar) as current_month,
  CAST(day(current_date) AS varchar) as current_day;

-- 確認した日付を使用してクエリを実行
SELECT * FROM your_table
WHERE year = '2025' AND month = '01' AND day = '17';
```

#### 方法2: 複数日を指定
```sql
-- 過去数日のデータを取得
SELECT * FROM your_table
WHERE year = '2025' AND month = '01'
AND day IN ('15', '16', '17');
```

#### 方法3: より広い範囲を指定
```sql
-- 月全体のデータを取得
SELECT * FROM your_table
WHERE year = '2025' AND month = '01';
```

**注意**: パーティション投影では、パーティション列（year, month, day, hour）に対して動的関数は使用できません。事前に日付を計算して具体的な値を指定する必要があります。

### 6. "Only one sql statement is allowed" エラー

**問題**: Athenaは1つのクエリで複数のSQLステートメントを許可していません。コメントアウトされたSELECT文や複数の文がある場合にこのエラーが発生します。

**解決方法**:
- 単一のSQLステートメントのみを含むクエリを実行
- コメントアウトされた追加のSELECT文は削除
- 必要に応じて別々のクエリとして実行

**修正されたテンプレート**: すべてのSQLテンプレートは単一のステートメントのみを含むよう修正済み

**追加クエリ用テンプレート**:
- `multi_day_query.sql`: 複数日のデータ取得
- `monthly_query.sql`: 月全体のデータ取得
- `current_date_helper.sql`: 現在日付の確認
- `partition_repair.sql`: パーティション修復

## 注意事項

1. **S3データ構造**: この設定は特定のS3パーティション構造を前提としています
2. **日付範囲**: パーティション投影は2020-2030年の範囲で設定されています
3. **タイムゾーン**: 日付/時刻の処理はUTCベースです
4. **権限**: 適切なIAMロールとポリシーが設定されていることを確認してください

## 実際のテーブルスキーマについて

実際のテーブルスキーマは以下の通りです：

### パーティション構造
- **パーティション列**: `partition_0`, `partition_1`, `partition_2`, `partition_3`, `partition_4`
- **対応関係**:
  - `partition_0` = year (年)
  - `partition_1` = month (月)
  - `partition_2` = day (日)
  - `partition_3` = hour (時)
  - `partition_4` = 追加レベル

### テーブル別スキーマ

#### django_web テーブル
- date, container_name, source, log, container_id, ec2_instance_id, ecs_cluster, ecs_task_arn, ecs_task_definition

#### nginx_web テーブル
- date, container_id, container_name, source, log, ec2_instance_id, ecs_cluster, ecs_task_arn, ecs_task_definition, partial_last, partial_message, partial_id, partial_ordinal

#### error テーブル
- date, container_id, container_name, source, log, ec2_instance_id, ecs_cluster, ecs_task_arn, ecs_task_definition

### 修正されたクエリ例

```sql
-- 実際のスキーマに基づくクエリ
SELECT
    date,
    container_name,
    source,
    log,
    container_id,
    ec2_instance_id,
    ecs_cluster,
    ecs_task_arn,
    ecs_task_definition,
    partition_0 as year,
    partition_1 as month,
    partition_2 as day,
    partition_3 as hour
FROM rcs_stg_web_logs.`rcs-stg-django_web`
WHERE
    partition_0 = '2025'  -- 年
    AND partition_1 = '01' -- 月
    AND partition_2 = '17' -- 日
    AND partition_3 IN ('12', '13', '14', '15', '16', '17', '18', '19', '20', '21', '22', '23')
ORDER BY date DESC
LIMIT 50;
```

## 更新履歴

- **2025-01-17**: 初回修正 - JSON SerDe設定、パーティション投影、サンプルクエリの修正
- **2025-01-17**: 緊急修正 - "Queries of this type are not supported"エラーの解決
  - パーティション投影での動的日付関数の問題を修正
  - サンプルクエリを具体的な日付指定に変更
  - 動的日付クエリテンプレート（`dynamic_date_query_template.sql`）を追加
  - トラブルシューティング情報を拡充
- **2025-01-17**: 実スキーマ対応修正 - 実際のテーブル構造に合わせた修正
  - パーティション列名を`partition_0`～`partition_4`に変更
  - 各テーブルの実際のカラム構造に合わせてクエリを修正
  - nginx_webテーブルの追加カラム（partial_*）に対応
  - create_table.sqlテンプレートをGlue Crawler対応に変更
- **2025-01-17**: 単一SQLステートメント対応 - "Only one sql statement is allowed"エラーの解決
  - すべてのSQLテンプレートから余分なコメントと複数のSELECT文を削除
  - 各テンプレートを単一のクリーンなSQLステートメントに修正
  - 追加クエリのために別ファイルを作成（`multi_day_query.sql`, `monthly_query.sql`, `current_date_helper.sql`, `partition_repair.sql`）
  - セミコロンを削除してより互換性の高い形式に修正
