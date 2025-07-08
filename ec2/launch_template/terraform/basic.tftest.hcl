# ==================================================
# EC2 Launch Template Module - Basic Tests
# ==================================================
#
# このファイルは Launch Template モジュールの基本的な動作確認を行います
#
# テスト内容:
#   - Launch Template の基本作成
#   - Security Group の作成と設定
#   - SSM Parameter Store の作成と設定
#   - Mackerel 設定の検証
#   - CloudWatch Agent 設定の検証
#   - タグ戦略の検証
#   - 出力値の検証
#
# 最新更新: 2024年12月
# ==================================================

# Test 1: 基本的な Launch Template 作成
run "basic_launch_template" {
  command = plan

  variables {
    project_name                 = "test"
    environment                  = "dev"
    app                          = "sample"
    instance_type                = "t3.micro"
    key_name                     = "test-key"
    volume_size                  = 20
    ssh_cidr_blocks              = ["10.0.0.0/16"]
    ecs_cluster_name             = "test-ecs-cluster"
    mackerel_api_key             = "dummy-api-key"
    mackerel_organization        = "test-org"
    mackerel_roles               = "test,launch-template"
    cloudwatch_default_namespace = "Test/LaunchTemplate"
  }

  assert {
    condition     = aws_launch_template.main.name == "test-dev-launch-template"
    error_message = "Launch Template name should be project-environment-launch-template"
  }

  assert {
    condition     = aws_launch_template.main.instance_type == "t3.micro"
    error_message = "Launch Template instance type should be t3.micro"
  }

  assert {
    condition     = aws_launch_template.main.key_name == "test-key"
    error_message = "Launch Template key name should be test-key"
  }

  assert {
    condition     = aws_launch_template.main.vpc_security_group_ids == [aws_security_group.main.id]
    error_message = "Launch Template should use the created security group"
  }

  assert {
    condition     = aws_launch_template.main.block_device_mappings[0].ebs[0].volume_size == 20
    error_message = "EBS volume size should be 20 GB"
  }

  assert {
    condition     = aws_launch_template.main.block_device_mappings[0].ebs[0].volume_type == "gp3"
    error_message = "EBS volume type should be gp3"
  }

  assert {
    condition     = aws_launch_template.main.block_device_mappings[0].ebs[0].encrypted == true
    error_message = "EBS volume should be encrypted"
  }
}

# Test 2: Security Group 設定の確認
run "security_group_configuration" {
  command = plan

  variables {
    project_name    = "test"
    environment     = "dev"
    app             = "sample"
    ssh_cidr_blocks = ["10.0.0.0/16"]
  }

  assert {
    condition     = aws_security_group.main.name == "test-dev-ec2-sg"
    error_message = "Security Group name should be project-environment-ec2-sg"
  }

  assert {
    condition     = aws_security_group.main.description == "EC2インスタンス用セキュリティグループ"
    error_message = "Security Group description should be appropriate"
  }

  assert {
    condition     = length(aws_security_group.main.ingress) >= 4
    error_message = "Security Group should have at least 4 ingress rules (SSH, HTTP, HTTPS, ECS)"
  }

  # SSH rule check
  assert {
    condition     = contains([for rule in aws_security_group.main.ingress : rule.from_port], 22)
    error_message = "Security Group should allow SSH on port 22"
  }

  # HTTP rule check
  assert {
    condition     = contains([for rule in aws_security_group.main.ingress : rule.from_port], 80)
    error_message = "Security Group should allow HTTP on port 80"
  }

  # HTTPS rule check
  assert {
    condition     = contains([for rule in aws_security_group.main.ingress : rule.from_port], 443)
    error_message = "Security Group should allow HTTPS on port 443"
  }

  # ECS dynamic port mapping rule check
  assert {
    condition     = contains([for rule in aws_security_group.main.ingress : rule.from_port], 32768)
    error_message = "Security Group should allow ECS dynamic port mapping"
  }

  assert {
    condition     = length(aws_security_group.main.egress) >= 1
    error_message = "Security Group should have at least 1 egress rule"
  }
}

# Test 3: AMI データソースの確認
run "ami_data_source" {
  command = plan

  variables {
    project_name    = "test"
    environment     = "dev"
    ami_name_filter = ["amzn2023-ami-ecs-*"]
  }

  assert {
    condition     = data.aws_ami.amazon_linux.most_recent == true
    error_message = "AMI should be the most recent version"
  }

  assert {
    condition     = contains(data.aws_ami.amazon_linux.owners, "amazon")
    error_message = "AMI should be owned by Amazon"
  }

  assert {
    condition     = aws_launch_template.main.image_id == data.aws_ami.amazon_linux.id
    error_message = "Launch Template should use the selected AMI"
  }
}

# Test 4: Mackerel 設定の Parameter Store テスト
run "mackerel_parameter_store" {
  command = plan

  variables {
    project_name           = "test"
    environment            = "dev"
    mackerel_api_key       = "dummy-api-key"
    mackerel_organization  = "test-org"
    mackerel_roles         = "test,launch-template"
    create_parameter_store = true
  }

  assert {
    condition     = aws_ssm_parameter.mackerel_api_key[0].name == "/test/dev/mackerel/api_key"
    error_message = "Mackerel API key parameter should have correct name"
  }

  assert {
    condition     = aws_ssm_parameter.mackerel_api_key[0].type == "SecureString"
    error_message = "Mackerel API key should be SecureString type"
  }

  assert {
    condition     = aws_ssm_parameter.mackerel_display_name[0].name == "/test/dev/mackerel/display_name"
    error_message = "Mackerel display name parameter should have correct name"
  }

  assert {
    condition     = aws_ssm_parameter.mackerel_organization[0].name == "/test/dev/mackerel/organization"
    error_message = "Mackerel organization parameter should have correct name"
  }

  assert {
    condition     = aws_ssm_parameter.mackerel_roles[0].name == "/test/dev/mackerel/roles"
    error_message = "Mackerel roles parameter should have correct name"
  }

  assert {
    condition     = aws_ssm_parameter.mackerel_agent_config[0].name == "/test/dev/mackerel/agent_config"
    error_message = "Mackerel agent config parameter should have correct name"
  }
}

# Test 5: CloudWatch Agent 設定の Parameter Store テスト
run "cloudwatch_parameter_store" {
  command = plan

  variables {
    project_name                     = "test"
    environment                      = "dev"
    cloudwatch_default_namespace     = "Test/LaunchTemplate"
    create_parameter_store           = true
    create_default_cloudwatch_config = true
  }

  assert {
    condition     = aws_ssm_parameter.cloudwatch_agent_config[0].name == "AmazonCloudWatch-Agent_test-dev-ecs"
    error_message = "CloudWatch Agent config parameter should have correct name"
  }

  assert {
    condition     = aws_ssm_parameter.cloudwatch_agent_config[0].type == "String"
    error_message = "CloudWatch Agent config should be String type"
  }

  assert {
    condition     = aws_ssm_parameter.cloudwatch_agent_config[0].tier == "Standard"
    error_message = "CloudWatch Agent config should be Standard tier"
  }
}

# Test 6: カスタム Launch Template 名
run "custom_launch_template_name" {
  command = plan

  variables {
    project_name  = "myproject"
    environment   = "prd"
    app           = "webapp"
    instance_type = "t3.small"
  }

  assert {
    condition     = aws_launch_template.main.name == "myproject-prd-launch-template"
    error_message = "Custom launch template name should be myproject-prd-launch-template"
  }

  assert {
    condition     = aws_launch_template.main.instance_type == "t3.small"
    error_message = "Custom instance type should be t3.small"
  }

  assert {
    condition     = aws_security_group.main.name == "myproject-prd-ec2-sg"
    error_message = "Custom security group name should be myproject-prd-ec2-sg"
  }
}

# Test 7: ECS クラスター名の設定
run "ecs_cluster_configuration" {
  command = plan

  variables {
    project_name     = "test"
    environment      = "dev"
    ecs_cluster_name = "custom-ecs-cluster"
  }

  assert {
    condition     = contains(aws_launch_template.main.user_data, "custom-ecs-cluster")
    error_message = "User data should contain the custom ECS cluster name"
  }

  assert {
    condition     = contains(aws_launch_template.main.user_data, "ECS_CLUSTER=custom-ecs-cluster")
    error_message = "User data should set ECS_CLUSTER environment variable"
  }
}

# Test 8: タグ戦略の検証
run "tag_strategy_validation" {
  command = plan

  variables {
    project_name = "test"
    environment  = "dev"
    app          = "sample"
    owner_team   = "platform"
    owner_email  = "platform@example.com"
    cost_center  = "12345"
    common_tags = {
      "CustomTag" = "CustomValue"
      "Team"      = "Engineering"
    }
  }

  assert {
    condition     = aws_launch_template.main.tags["Project"] == "test"
    error_message = "Launch Template should have Project tag"
  }

  assert {
    condition     = aws_launch_template.main.tags["Environment"] == "dev"
    error_message = "Launch Template should have Environment tag"
  }

  assert {
    condition     = aws_launch_template.main.tags["Application"] == "sample"
    error_message = "Launch Template should have Application tag"
  }

  assert {
    condition     = aws_launch_template.main.tags["ManagedBy"] == "terraform"
    error_message = "Launch Template should have ManagedBy tag"
  }

  assert {
    condition     = aws_launch_template.main.tags["Owner"] == "platform"
    error_message = "Launch Template should have Owner tag"
  }

  assert {
    condition     = aws_launch_template.main.tags["OwnerEmail"] == "platform@example.com"
    error_message = "Launch Template should have OwnerEmail tag"
  }

  assert {
    condition     = aws_launch_template.main.tags["CustomTag"] == "CustomValue"
    error_message = "Launch Template should have custom tags"
  }

  assert {
    condition     = aws_launch_template.main.tags["Team"] == "Engineering"
    error_message = "Launch Template should have Team tag"
  }
}

# Test 9: 本番環境固有の設定
run "production_environment_settings" {
  command = plan

  variables {
    project_name        = "prd-app"
    environment         = "prd"
    app                 = "webapp"
    instance_type       = "t3.medium"
    volume_size         = 50
    volume_type         = "gp3"
    monitoring_level    = "enhanced"
    data_classification = "confidential"
  }

  assert {
    condition     = aws_launch_template.main.tags["CriticalityLevel"] == "high"
    error_message = "Production environment should have high criticality level"
  }

  assert {
    condition     = aws_launch_template.main.tags["AuditRequired"] == "yes"
    error_message = "Production environment should require audit"
  }

  assert {
    condition     = aws_launch_template.main.tags["RetentionPeriod"] == "7-years"
    error_message = "Production environment should have 7-years retention"
  }

  assert {
    condition     = aws_launch_template.main.tags["DataClassification"] == "confidential"
    error_message = "Production environment should have confidential data classification"
  }

  assert {
    condition     = aws_launch_template.main.tags["MonitoringLevel"] == "enhanced"
    error_message = "Production environment should have enhanced monitoring"
  }

  assert {
    condition     = aws_launch_template.main.block_device_mappings[0].ebs[0].volume_size == 50
    error_message = "Production environment should have 50 GB volume"
  }

  assert {
    condition     = aws_launch_template.main.block_device_mappings[0].ebs[0].volume_type == "gp3"
    error_message = "Production environment should use gp3 volume type"
  }
}

# Test 10: カスタムユーザーデータの確認
run "custom_user_data" {
  command = plan

  variables {
    project_name     = "test"
    environment      = "dev"
    custom_user_data = "#!/bin/bash\necho 'Custom script executed'"
  }

  assert {
    condition     = contains(aws_launch_template.main.user_data, "Custom script executed")
    error_message = "Launch Template should contain custom user data"
  }

  assert {
    condition     = contains(aws_launch_template.main.user_data, "#!/bin/bash")
    error_message = "Launch Template should contain bash shebang"
  }
}

# Test 11: 出力値の検証
run "outputs_validation" {
  command = plan

  variables {
    project_name           = "test"
    environment            = "dev"
    app                    = "sample"
    mackerel_api_key       = "dummy-api-key"
    mackerel_organization  = "test-org"
    mackerel_roles         = "test,launch-template"
    create_parameter_store = true
  }

  assert {
    condition     = output.launch_template_name == "test-dev-launch-template"
    error_message = "Launch Template name output should be correct"
  }

  assert {
    condition     = output.security_group_name == "test-dev-ec2-sg"
    error_message = "Security Group name output should be correct"
  }

  assert {
    condition     = output.ami_name != ""
    error_message = "AMI name output should not be empty"
  }

  assert {
    condition     = output.mackerel_parameter_prefix == "/test/dev/mackerel/"
    error_message = "Mackerel parameter prefix output should be correct"
  }

  assert {
    condition     = output.effective_mackerel_settings.display_name == "test-dev-sample"
    error_message = "Effective Mackerel display name should be correct"
  }

  assert {
    condition     = output.effective_mackerel_settings.roles == "test,launch-template"
    error_message = "Effective Mackerel roles should be correct"
  }

  assert {
    condition     = output.effective_cloudwatch_settings.namespace == "test-metrics"
    error_message = "Effective CloudWatch namespace should be correct"
  }

  assert {
    condition     = output.effective_cloudwatch_settings.collection_interval == 60
    error_message = "Effective CloudWatch collection interval should be 60"
  }

  assert {
    condition     = length(output.parameter_store_names) >= 6
    error_message = "Parameter store names should contain at least 6 items"
  }
}

# Test 12: IAM Instance Profile 設定
run "iam_instance_profile" {
  command = plan

  variables {
    project_name              = "test"
    environment               = "dev"
    iam_instance_profile_name = "test-instance-profile"
  }

  assert {
    condition     = aws_launch_template.main.iam_instance_profile[0].name == "test-instance-profile"
    error_message = "Launch Template should use the specified IAM instance profile"
  }
}

# Test 13: 高度な CloudWatch 設定
run "advanced_cloudwatch_config" {
  command = plan

  variables {
    project_name                           = "test"
    environment                            = "dev"
    cloudwatch_default_namespace           = "CustomNamespace"
    cloudwatch_metrics_collection_interval = 30
    cloudwatch_cpu_metrics = {
      measurement                 = ["cpu_usage_idle", "cpu_usage_user", "cpu_usage_system"]
      metrics_collection_interval = 30
      totalcpu                    = true
    }
    cloudwatch_enable_statsd = true
    cloudwatch_statsd_port   = 8125
  }

  assert {
    condition     = output.effective_cloudwatch_settings.namespace == "CustomNamespace"
    error_message = "CloudWatch namespace should be CustomNamespace"
  }

  assert {
    condition     = output.effective_cloudwatch_settings.collection_interval == 30
    error_message = "CloudWatch collection interval should be 30"
  }
}

# Test 14: 異なるボリュームタイプの設定
run "different_volume_types" {
  command = plan

  variables {
    project_name = "test"
    environment  = "dev"
    volume_type  = "gp2"
    volume_size  = 30
  }

  assert {
    condition     = aws_launch_template.main.block_device_mappings[0].ebs[0].volume_type == "gp2"
    error_message = "EBS volume type should be gp2"
  }

  assert {
    condition     = aws_launch_template.main.block_device_mappings[0].ebs[0].volume_size == 30
    error_message = "EBS volume size should be 30 GB"
  }
}

# Test 15: SSH アクセス制限の確認
run "ssh_access_restrictions" {
  command = plan

  variables {
    project_name    = "test"
    environment     = "dev"
    ssh_cidr_blocks = ["10.0.0.0/8", "172.16.0.0/12"]
  }

  assert {
    condition     = length([for rule in aws_security_group.main.ingress : rule if rule.from_port == 22 && contains(rule.cidr_blocks, "10.0.0.0/8")]) > 0
    error_message = "SSH should be allowed from 10.0.0.0/8"
  }

  assert {
    condition     = length([for rule in aws_security_group.main.ingress : rule if rule.from_port == 22 && contains(rule.cidr_blocks, "172.16.0.0/12")]) > 0
    error_message = "SSH should be allowed from 172.16.0.0/12"
  }
}
