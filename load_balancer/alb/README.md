# Application Load Balancer (ALB) for ECS

このディレクトリには、ECS用のApplication Load Balancer (ALB) の構築に必要なTerraformファイルが含まれています。

## 構成

- `terraform/` - Terraformファイル
  - `main.tf` - ALBリソースの定義
  - `variables.tf` - 変数定義
  - `outputs.tf` - 出力値定義
  - `versions.tf` - プロバイダーバージョン設定
  - `terraform.tfvars.example` - 変数の設定例

## 使用方法

### 1. 変数ファイルの作成
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

### 2. 変数ファイルの編集
`terraform.tfvars` を環境に応じて編集してください。

**必須項目：**
- `vpc_id` - ALBを配置するVPCのID
- `subnet_ids` - ALBを配置するサブネットIDのリスト（最低2つのAZ）
- `ssl_certificate_arn` - SSL証明書のARN（HTTPSリスナーで必須）

**設定例：**
```bash
# 基本設定
project = "myproject"
env     = "dev"

# ネットワーク設定（必須）
vpc_id = "vpc-xxxxxxxxx"
subnet_ids = [
  "subnet-xxxxxxxxx",  # ap-northeast-1a
  "subnet-yyyyyyyyy",  # ap-northeast-1c
]

# SSL証明書（必須）
ssl_certificate_arn = "arn:aws:acm:ap-northeast-1:123456789012:certificate/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
```

### 3. Terraformの実行
```bash
terraform init
terraform plan
terraform apply
```

## ECS固有の特徴

- **ターゲットタイプ**: `ip` を使用（ECSタスクはIPベースでターゲットに登録）
- **Deregistration遅延**: 30秒に設定（ECSタスクの停止時間を短縮）
- **ヘルスチェック**: ECS用に最適化された間隔とタイムアウト設定
  - 間隔: 15秒
  - タイムアウト: 10秒
  - ポート: `traffic-port`（ターゲットと同じポート）
- **ECSサービス統合**: ECSサービスから自動的にターゲット登録が可能
- **セキュリティグループ**: HTTP(80)とHTTPS(443)ポートをIPv4/IPv6の全トラフィックに対して許可
- **リスナー設定**:
  - HTTPリスナー（80番ポート）: 自動的にHTTPS（443番ポート）にリダイレクト
  - HTTPSリスナー（443番ポート）: 404 Not Foundを返す（SSL証明書が必要）

## 作成されるリソース

このTerraformモジュールは以下のリソースを作成します：

1. **Application Load Balancer (ALB)** - メインのロードバランサー
2. **セキュリティグループ** - ALB用のセキュリティグループ
3. **ターゲットグループ** - ECS用のIPベースターゲットグループ
4. **HTTPリスナー** - 80番ポートでHTTPSにリダイレクト
5. **HTTPSリスナー** - 443番ポートでSSL終端

## ECSサービスとの連携

このALBはECSサービスと以下のように連携します：

1. ECSサービス作成時に `load_balancer` ブロックでこのターゲットグループを指定
2. ECSタスクが起動すると自動的にターゲットグループに登録
3. ヘルスチェックに成功するとトラフィックが流される
4. ECSタスクが停止すると自動的にターゲットグループから削除

### ECSサービスでの設定例

```hcl
resource "aws_ecs_service" "web" {
  name            = "${var.project_name}-${var.environment}-web"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.web.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  # ALBとの統合
  load_balancer {
    target_group_arn = module.alb.target_group_arn
    container_name   = "web"
    container_port   = 80
  }

  # ALBのヘルスチェックに依存
  depends_on = [module.alb]
}
```

## 重要な設定事項

### SSL証明書の準備
HTTPSリスナーを使用するため、事前にAWS Certificate Manager (ACM)でSSL証明書を作成し、そのARNを設定する必要があります。

### リスナーの動作
- **HTTP (80番ポート)**: すべてのリクエストを自動的にHTTPS (443番ポート)にリダイレクト（301リダイレクト）
- **HTTPS (443番ポート)**: デフォルトで404 Not Foundを返す（カスタムルールを追加することで特定のパスにルーティング可能）

### ヘルスチェック設定
- **ポート**: `traffic-port` - ターゲットと同じポートを使用
- **パス**: `/` - ルートパスでヘルスチェック
- **プロトコル**: `HTTP`
- **間隔**: 15秒（ECS用に最適化）
- **タイムアウト**: 10秒

## トラブルシューティング

### よくある問題と解決方法

#### 1. `health_check_port` のエラー
```
Error: "health_check.0.port" must be a valid port number (1-65536) or "traffic-port"
```
**解決方法**: `terraform.tfvars`で`health_check_port = "traffic-port"`と設定する

#### 2. 変数参照エラー
```
Error: Variables not allowed
```
**解決方法**: `variables.tf`のdefault値で他の変数を参照しないようにする

#### 3. SSL証明書エラー
```
Error: InvalidCertificateArn
```
**解決方法**: 正しいSSL証明書のARNを`ssl_certificate_arn`に設定する

### 設定の確認

実際にリソースを作成する前に、設定が正しいか確認してください：

```bash
# 設定の確認
terraform plan

# 設定の詳細確認
terraform plan -out=tfplan
terraform show tfplan
```

## 注意事項

- **ALB削除時**: ALBを削除する際は、関連するリソース（ターゲットグループ、リスナーなど）も併せて削除されます
- **セキュリティグループ**: デフォルトで全てのIPv4/IPv6トラフィックからのHTTP/HTTPSアクセスを許可します
- **ECSサービス削除**: ECSサービスを削除する前にALBから切り離してください
- **SSL証明書**: HTTPSリスナーにはSSL証明書のARNが必須です
- **サブネット**: 最低2つの異なるAZのサブネットが必要です
- **共通タグ**: プロジェクト固有のタグは`terraform.tfvars`の`common_tags`で設定してください

## 参考資料

- [ECS統合例](./ecs-integration-example.tf) - ECSサービスとの統合例
- [AWS Application Load Balancer ドキュメント](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/)
- [ECS Service Load Balancer 設定](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-load-balancing.html)
