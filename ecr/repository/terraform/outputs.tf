# ==================================================
# ECRリポジトリ情報
# ==================================================

output "repository_urls" {
  description = "ECRリポジトリのURLのマップ"
  value       = { for k, v in aws_ecr_repository.main : k => v.repository_url }
}

output "repository_arns" {
  description = "ECRリポジトリのARNのマップ"
  value       = { for k, v in aws_ecr_repository.main : k => v.arn }
}

output "repository_names" {
  description = "ECRリポジトリ名のマップ"
  value       = { for k, v in aws_ecr_repository.main : k => v.name }
}

output "registry_ids" {
  description = "ECRレジストリIDのマップ"
  value       = { for k, v in aws_ecr_repository.main : k => v.registry_id }
}

# ==================================================
# 単一リポジトリ用出力（後方互換性）
# ==================================================

output "repository_url" {
  description = "メインECRリポジトリのURL（単一リポジトリ作成時）"
  value       = length(var.repositories) == 0 ? values(aws_ecr_repository.main)[0].repository_url : null
}

output "repository_arn" {
  description = "メインECRリポジトリのARN（単一リポジトリ作成時）"
  value       = length(var.repositories) == 0 ? values(aws_ecr_repository.main)[0].arn : null
}

output "repository_name" {
  description = "メインECRリポジトリ名（単一リポジトリ作成時）"
  value       = length(var.repositories) == 0 ? values(aws_ecr_repository.main)[0].name : null
}

output "registry_id" {
  description = "ECRレジストリID（単一リポジトリ作成時）"
  value       = length(var.repositories) == 0 ? values(aws_ecr_repository.main)[0].registry_id : null
}

# ==================================================
# イメージURI生成ヘルパー
# ==================================================

output "repository_image_uris" {
  description = "最新イメージタグ用のURIのマップ"
  value = {
    for k, v in aws_ecr_repository.main : k => "${v.repository_url}:latest"
  }
}

output "repository_push_commands" {
  description = "docker pushコマンドの例"
  value = {
    for k, v in aws_ecr_repository.main :
    k => [
      "aws ecr get-login-password --region ${data.aws_region.current.name} | docker login --username AWS --password-stdin ${v.registry_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com",
      "docker build -t ${k} .",
      "docker tag ${k}:latest ${v.repository_url}:latest",
      "docker push ${v.repository_url}:latest"
    ]
  }
}

# ==================================================
# 設定情報
# ==================================================

output "lifecycle_policy_enabled" {
  description = "ライフサイクルポリシーが有効かどうか"
  value       = var.enable_lifecycle_policy
}

output "repository_policy_enabled" {
  description = "リポジトリポリシーが有効かどうか"
  value       = var.enable_repository_policy
}

output "replication_enabled" {
  description = "レプリケーションが有効かどうか"
  value       = var.enable_replication
}

output "scan_on_push_enabled" {
  description = "プッシュ時スキャンが有効かどうか（デフォルト設定）"
  value       = var.scan_on_push
}

# ==================================================
# レプリケーション情報
# ==================================================

output "replication_destinations" {
  description = "レプリケーション先リージョンのリスト"
  value       = var.enable_replication ? var.replication_destinations : []
}

# ==================================================
# アカウント・リージョン情報
# ==================================================

output "aws_account_id" {
  description = "現在のAWSアカウントID"
  value       = data.aws_caller_identity.current.account_id
}

output "aws_region" {
  description = "現在のAWSリージョン"
  value       = data.aws_region.current.name
}
