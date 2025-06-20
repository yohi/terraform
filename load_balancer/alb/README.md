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

1. 変数ファイルの作成
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

2. 変数ファイルの編集
`terraform.tfvars` を環境に応じて編集してください。

3. Terraformの実行
```bash
terraform init
terraform plan
terraform apply
```

## ECS固有の特徴

- **ターゲットタイプ**: `ip` を使用（ECSタスクはIPベースでターゲットに登録）
- **デregistration遅延**: 30秒に設定（ECSタスクの停止時間を短縮）
- **ヘルスチェック**: ECS用に最適化された間隔とタイムアウト設定
- **ECSサービス統合**: ECSサービスから自動的にターゲット登録が可能
- **セキュリティグループ**: HTTP(80)とHTTPS(443)ポートをIPv4/IPv6の全トラフィックに対して許可
- **リスナー設定**:
  - HTTPリスナー（80番ポート）: 自動的にHTTPS（443番ポート）にリダイレクト
  - HTTPSリスナー（443番ポート）: 404 Not Foundを返す（SSL証明書が必要）

## ECSサービスとの連携

このALBはECSサービスと以下のように連携します：

1. ECSサービス作成時に `load_balancer` ブロックでこのターゲットグループを指定
2. ECSタスクが起動すると自動的にターゲットグループに登録
3. ヘルスチェックに成功するとトラフィックが流される
4. ECSタスクが停止すると自動的にターゲットグループから削除

## 重要な設定事項

### SSL証明書の準備
HTTPSリスナーを使用するため、事前にAWS Certificate Manager (ACM)でSSL証明書を作成し、そのARNを設定する必要があります。

### リスナーの動作
- **HTTP (80番ポート)**: すべてのリクエストを自動的にHTTPS (443番ポート)にリダイレクト（301リダイレクト）
- **HTTPS (443番ポート)**: デフォルトで404 Not Foundを返す（カスタムルールを追加することで特定のパスにルーティング可能）

## 注意事項

- ALBを削除する際は、関連するリソース（ターゲットグループ、リスナーなど）も併せて削除されます
- セキュリティグループの設定に注意してください
- ECSサービスを削除する前にALBから切り離してください
- **SSL証明書のARNは必須です** - `terraform.tfvars`で適切な値を設定してください
