# ==================================================
# EC2 Launch Template Module - Integration Tests
# ==================================================
#
# このファイルは Launch Template モジュールの統合テストを行います
# 実際のAWSリソースを使用してテストを実行します
#
# ⚠️  警告: このテストは実際のAWSリソースを作成するため、コストが発生します
# ⚠️  AWS認証情報が必要です
#
# テスト内容:
#   - 実際の Launch Template 作成
#   - 実際の Security Group 作成
#   - 実際の SSM Parameter Store 作成
#   - 実際の AMI データソース使用
#   - 実際の出力値検証
#
# 最新更新: 2024年12月
# ==================================================

# Test 1: 基本的な統合テスト
run "basic_integration" {
  command = apply_and_destroy

  variables {
    project_name                 = "test-integration"
    environment                  = "dev"
    app                          = "integration-test"
    instance_type                = "t3.micro"
    key_name                     = "" # キーペアなしでテスト
    volume_size                  = 20
    ssh_cidr_blocks              = [] # SSH無効でテスト
    ecs_cluster_name             = "test-integration-ecs"
    mackerel_api_key             = "dummy-api-key-integration"
    mackerel_organization        = "test-org"
    mackerel_roles               = "test,integration"
    cloudwatch_default_namespace = "Test/Integration"
    create_parameter_store       = true
  }

  assert {
    condition     = aws_launch_template.main.name == "test-integration-dev-launch-template"
    error_message = "Launch Template should be created with correct name"
  }

  assert {
    condition     = aws_launch_template.main.instance_type == "t3.micro"
    error_message = "Launch Template should have correct instance type"
  }

  assert {
    condition     = aws_security_group.main.name == "test-integration-dev-ec2-sg"
    error_message = "Security Group should be created with correct name"
  }

  assert {
    condition     = output.launch_template_id != ""
    error_message = "Launch Template ID should be generated"
  }

  assert {
    condition     = output.launch_template_arn != ""
    error_message = "Launch Template ARN should be generated"
  }

  assert {
    condition     = output.ami_id != ""
    error_message = "AMI ID should be resolved"
  }

  assert {
    condition     = output.ami_name != ""
    error_message = "AMI name should be resolved"
  }

  assert {
    condition     = output.security_group_id != ""
    error_message = "Security Group ID should be generated"
  }

  # Note: parameter_store_names output assertion removed because it references sensitive values
}

# Test 2: 本番環境設定での統合テスト
run "production_integration" {
  command = apply_and_destroy

  variables {
    project_name                 = "test-prod-integration"
    environment                  = "prd"
    app                          = "prod-app"
    instance_type                = "t3.small"
    volume_size                  = 30
    volume_type                  = "gp3"
    ecs_cluster_name             = "test-prod-integration-ecs"
    mackerel_api_key             = "prod-dummy-api-key"
    mackerel_organization        = "prod-org"
    mackerel_roles               = "prod,web"
    cloudwatch_default_namespace = "Prod/Test"
    create_parameter_store       = true
    owner_team                   = "platform"
    owner_email                  = "platform@example.com"
    cost_center                  = "12345"
    monitoring_level             = "enhanced"
    data_classification          = "confidential"
  }

  assert {
    condition     = aws_launch_template.main.name == "test-prod-integration-prd-launch-template"
    error_message = "Production Launch Template should be created"
  }

  assert {
    condition     = aws_launch_template.main.instance_type == "t3.small"
    error_message = "Production Launch Template should use t3.small"
  }

  assert {
    condition     = aws_launch_template.main.block_device_mappings[0].ebs[0].volume_size == 30
    error_message = "Production Launch Template should have 30 GB volume"
  }

  assert {
    condition     = aws_launch_template.main.block_device_mappings[0].ebs[0].volume_type == "gp3"
    error_message = "Production Launch Template should use gp3 volume"
  }

  assert {
    condition     = aws_launch_template.main.tags["CriticalityLevel"] == "high"
    error_message = "Production Launch Template should have high criticality"
  }

  assert {
    condition     = aws_launch_template.main.tags["AuditRequired"] == "yes"
    error_message = "Production Launch Template should require audit"
  }

  assert {
    condition     = aws_launch_template.main.tags["Owner"] == "platform"
    error_message = "Production Launch Template should have owner tag"
  }

  assert {
    condition     = aws_launch_template.main.tags["MonitoringLevel"] == "enhanced"
    error_message = "Production Launch Template should have enhanced monitoring"
  }

  assert {
    condition     = aws_launch_template.main.tags["DataClassification"] == "confidential"
    error_message = "Production Launch Template should have confidential data classification"
  }
}

# Test 3: カスタム設定での統合テスト
run "custom_configuration_integration" {
  command = apply_and_destroy

  variables {
    project_name                           = "test-custom"
    environment                            = "stg"
    app                                    = "custom-app"
    instance_type                          = "t3.medium"
    volume_size                            = 50
    volume_type                            = "gp2"
    associate_public_ip                    = false
    iam_instance_profile_name              = ""
    ecs_cluster_name                       = "test-custom-ecs"
    mackerel_api_key                       = "custom-api-key"
    mackerel_organization                  = "custom-org"
    mackerel_roles                         = "custom,staging"
    mackerel_parameter_prefix              = "/custom/prefix/mackerel/"
    cloudwatch_default_namespace           = "Custom/Staging"
    cloudwatch_metrics_collection_interval = 30
    create_parameter_store                 = true
    custom_user_data                       = "#!/bin/bash\necho 'Custom staging setup'"
  }

  assert {
    condition     = aws_launch_template.main.name == "test-custom-stg-launch-template"
    error_message = "Custom Launch Template should be created"
  }

  assert {
    condition     = aws_launch_template.main.instance_type == "t3.medium"
    error_message = "Custom Launch Template should use t3.medium"
  }

  assert {
    condition     = aws_launch_template.main.block_device_mappings[0].ebs[0].volume_size == 50
    error_message = "Custom Launch Template should have 50 GB volume"
  }

  assert {
    condition     = aws_launch_template.main.block_device_mappings[0].ebs[0].volume_type == "gp2"
    error_message = "Custom Launch Template should use gp2 volume"
  }

  assert {
    condition     = aws_launch_template.main.network_interfaces[0].associate_public_ip_address == false
    error_message = "Custom Launch Template should not associate public IP"
  }

  assert {
    condition     = contains(aws_launch_template.main.user_data, "Custom staging setup")
    error_message = "Custom Launch Template should contain custom user data"
  }

  assert {
    condition     = aws_ssm_parameter.mackerel_api_key[0].name == "/custom/prefix/mackerel/api_key"
    error_message = "Custom Mackerel parameter should use custom prefix"
  }

  assert {
    condition     = output.mackerel_parameter_prefix == "/custom/prefix/mackerel/"
    error_message = "Custom Mackerel parameter prefix should be in output"
  }

  # Note: effective_cloudwatch_settings output assertions removed because they reference sensitive values
}

# Test 4: SSH制限ありでの統合テスト
run "ssh_restricted_integration" {
  command = apply_and_destroy

  variables {
    project_name           = "test-ssh-restricted"
    environment            = "dev"
    app                    = "ssh-test"
    instance_type          = "t3.micro"
    key_name               = "test-key"
    ssh_cidr_blocks        = ["10.0.0.0/16", "172.16.0.0/12"]
    ecs_cluster_name       = "test-ssh-restricted-ecs"
    mackerel_api_key       = "ssh-test-api-key"
    mackerel_organization  = "ssh-test-org"
    mackerel_roles         = "ssh-test"
    create_parameter_store = true
  }

  assert {
    condition     = aws_launch_template.main.key_name == "test-key"
    error_message = "SSH restricted Launch Template should have key name"
  }

  assert {
    condition     = length([for rule in aws_security_group.main.ingress : rule if rule.from_port == 22 && contains(rule.cidr_blocks, "10.0.0.0/16")]) > 0
    error_message = "SSH should be allowed from 10.0.0.0/16"
  }

  assert {
    condition     = length([for rule in aws_security_group.main.ingress : rule if rule.from_port == 22 && contains(rule.cidr_blocks, "172.16.0.0/12")]) > 0
    error_message = "SSH should be allowed from 172.16.0.0/12"
  }

  assert {
    condition     = length([for rule in aws_security_group.main.ingress : rule if rule.from_port == 22 && contains(rule.cidr_blocks, "0.0.0.0/0")]) == 0
    error_message = "SSH should not be allowed from 0.0.0.0/0"
  }
}

# Test 5: 最小構成での統合テスト
run "minimal_configuration_integration" {
  command = apply_and_destroy

  variables {
    project_name = "test-minimal"
    environment  = "dev"
    # 他の設定はデフォルト値を使用
  }

  assert {
    condition     = aws_launch_template.main.name == "test-minimal-dev-launch-template"
    error_message = "Minimal Launch Template should be created"
  }

  assert {
    condition     = aws_launch_template.main.instance_type == "t3.micro"
    error_message = "Minimal Launch Template should use default instance type"
  }

  assert {
    condition     = aws_launch_template.main.block_device_mappings[0].ebs[0].volume_size == 20
    error_message = "Minimal Launch Template should use default volume size"
  }

  assert {
    condition     = aws_launch_template.main.block_device_mappings[0].ebs[0].volume_type == "gp3"
    error_message = "Minimal Launch Template should use default volume type"
  }

  assert {
    condition     = aws_launch_template.main.key_name == ""
    error_message = "Minimal Launch Template should not have key name"
  }

  assert {
    condition     = length([for rule in aws_security_group.main.ingress : rule if rule.from_port == 22]) == 0
    error_message = "Minimal Launch Template should not have SSH access"
  }

  # Note: effective_mackerel_settings and effective_cloudwatch_settings output assertions removed because they reference sensitive values
}

# Test 6: Parameter Store 無効での統合テスト
run "parameter_store_disabled_integration" {
  command = apply_and_destroy

  variables {
    project_name           = "test-no-params"
    environment            = "dev"
    app                    = "no-params"
    instance_type          = "t3.micro"
    mackerel_api_key       = "no-params-api-key"
    mackerel_organization  = "no-params-org"
    mackerel_roles         = "no-params"
    create_parameter_store = false
  }

  assert {
    condition     = aws_launch_template.main.name == "test-no-params-dev-launch-template"
    error_message = "No Parameter Store Launch Template should be created"
  }

  assert {
    condition     = length([for p in aws_ssm_parameter.mackerel_api_key : p]) == 0
    error_message = "Mackerel API key parameter should not be created"
  }

  assert {
    condition     = length([for p in aws_ssm_parameter.mackerel_organization : p]) == 0
    error_message = "Mackerel organization parameter should not be created"
  }

  assert {
    condition     = length([for p in aws_ssm_parameter.mackerel_roles : p]) == 0
    error_message = "Mackerel roles parameter should not be created"
  }

  assert {
    condition     = length([for p in aws_ssm_parameter.cloudwatch_agent_config : p]) == 0
    error_message = "CloudWatch agent config parameter should not be created"
  }

  # Note: parameter_store_names, effective_mackerel_settings and effective_cloudwatch_settings output assertions removed because they reference sensitive values
}

# Test 7: 高度な CloudWatch 設定での統合テスト
run "advanced_cloudwatch_integration" {
  command = apply_and_destroy

  variables {
    project_name                           = "test-advanced-cw"
    environment                            = "dev"
    app                                    = "advanced-cw"
    instance_type                          = "t3.micro"
    cloudwatch_default_namespace           = "Advanced/Test"
    cloudwatch_metrics_collection_interval = 30
    cloudwatch_cpu_metrics = {
      measurement                 = ["cpu_usage_idle", "cpu_usage_user", "cpu_usage_system"]
      metrics_collection_interval = 30
      totalcpu                    = true
    }
    cloudwatch_enable_statsd         = true
    cloudwatch_statsd_port           = 8125
    create_parameter_store           = true
    create_default_cloudwatch_config = true
  }

  assert {
    condition     = aws_launch_template.main.name == "test-advanced-cw-dev-launch-template"
    error_message = "Advanced CloudWatch Launch Template should be created"
  }

  assert {
    condition     = aws_ssm_parameter.cloudwatch_agent_config[0].name == "AmazonCloudWatch-Agent_test-advanced-cw-dev-ecs"
    error_message = "Advanced CloudWatch agent config parameter should be created"
  }

  # Note: effective_cloudwatch_settings output assertions removed because they reference sensitive values
}

# Test 8: 完全な出力値検証
run "complete_outputs_validation" {
  command = apply_and_destroy

  variables {
    project_name                 = "test-outputs"
    environment                  = "dev"
    app                          = "outputs-test"
    instance_type                = "t3.micro"
    volume_size                  = 25
    mackerel_api_key             = "outputs-api-key"
    mackerel_organization        = "outputs-org"
    mackerel_roles               = "outputs,test"
    cloudwatch_default_namespace = "Outputs/Test"
    create_parameter_store       = true
  }

  assert {
    condition     = output.launch_template_id != ""
    error_message = "Launch Template ID should be generated"
  }

  assert {
    condition     = output.launch_template_arn != ""
    error_message = "Launch Template ARN should be generated"
  }

  assert {
    condition     = output.launch_template_name == "test-outputs-dev-launch-template"
    error_message = "Launch Template name should be correct"
  }

  assert {
    condition     = output.launch_template_latest_version >= 1
    error_message = "Launch Template latest version should be at least 1"
  }

  assert {
    condition     = output.ami_id != ""
    error_message = "AMI ID should be resolved"
  }

  assert {
    condition     = output.ami_name != ""
    error_message = "AMI name should be resolved"
  }

  assert {
    condition     = output.security_group_id != ""
    error_message = "Security Group ID should be generated"
  }

  assert {
    condition     = output.security_group_name == "test-outputs-dev-ec2-sg"
    error_message = "Security Group name should be correct"
  }

  assert {
    condition     = output.mackerel_parameter_prefix == "/test-outputs/dev/mackerel/"
    error_message = "Mackerel parameter prefix should be correct"
  }

  # Note: effective_mackerel_settings, effective_cloudwatch_settings, and parameter_store_names output assertions removed because they reference sensitive values
}
