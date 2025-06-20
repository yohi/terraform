# ==================================================
# ALB情報
# ==================================================

output "alb_id" {
  description = "ALBのID"
  value       = aws_lb.main.id
}

output "alb_arn" {
  description = "ALBのARN"
  value       = aws_lb.main.arn
}

output "alb_arn_suffix" {
  description = "ALBのARNサフィックス"
  value       = aws_lb.main.arn_suffix
}

output "alb_name" {
  description = "ALBの名前"
  value       = aws_lb.main.name
}

output "alb_dns_name" {
  description = "ALBのDNS名"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "ALBのCanonical Hosted Zone ID"
  value       = aws_lb.main.zone_id
}

output "alb_hosted_zone_id" {
  description = "ALBのCanonical Hosted Zone ID（Route53レコード作成用）"
  value       = aws_lb.main.zone_id
}

# ==================================================
# ターゲットグループ情報
# ==================================================

output "target_group_id" {
  description = "ターゲットグループのID"
  value       = aws_lb_target_group.main.id
}

output "target_group_arn" {
  description = "ターゲットグループのARN"
  value       = aws_lb_target_group.main.arn
}

output "target_group_arn_suffix" {
  description = "ターゲットグループのARNサフィックス"
  value       = aws_lb_target_group.main.arn_suffix
}

output "target_group_name" {
  description = "ターゲットグループの名前"
  value       = aws_lb_target_group.main.name
}

# ==================================================
# リスナー情報
# ==================================================

output "http_listener_id" {
  description = "HTTPリスナーのID"
  value       = aws_lb_listener.http.id
}

output "http_listener_arn" {
  description = "HTTPリスナーのARN"
  value       = aws_lb_listener.http.arn
}

output "https_listener_id" {
  description = "HTTPSリスナーのID"
  value       = aws_lb_listener.https.id
}

output "https_listener_arn" {
  description = "HTTPSリスナーのARN"
  value       = aws_lb_listener.https.arn
}

# 後方互換性のため
output "listener_id" {
  description = "HTTPSリスナーのID（後方互換性のため）"
  value       = aws_lb_listener.https.id
}

output "listener_arn" {
  description = "HTTPSリスナーのARN（後方互換性のため）"
  value       = aws_lb_listener.https.arn
}

# ==================================================
# セキュリティグループ情報
# ==================================================

output "security_group_id" {
  description = "ALBのセキュリティグループID"
  value       = aws_security_group.alb.id
}

output "security_group_arn" {
  description = "ALBのセキュリティグループARN"
  value       = aws_security_group.alb.arn
}

output "security_group_name" {
  description = "ALBのセキュリティグループ名"
  value       = aws_security_group.alb.name
}

# ==================================================
# 接続情報
# ==================================================

output "load_balancer_url" {
  description = "ALBのURL（HTTPS）"
  value       = "https://${aws_lb.main.dns_name}"
}

output "load_balancer_http_url" {
  description = "ALBのHTTP URL（自動的にHTTPSにリダイレクト）"
  value       = "http://${aws_lb.main.dns_name}"
}

output "load_balancer_endpoint" {
  description = "ALBのエンドポイント（DNS名のみ）"
  value       = aws_lb.main.dns_name
}
