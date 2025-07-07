# ==================================================
# EC2 Launch Template Module - Validation Tests
# ==================================================
#
# このファイルは Launch Template モジュールの入力変数のバリデーションを行います
#
# テスト内容:
#   - 環境名の有効値テスト
#   - インスタンスタイプの検証
#   - ボリュームサイズの制約
#   - SSH CIDR ブロックの検証
#   - Mackerel 設定の検証
#   - CloudWatch 設定の検証
#
# 最新更新: 2024年12月
# ==================================================

# Test 1: 環境名の有効値テスト - 正常ケース
run "environment_valid_values" {
  command = plan

  variables {
    project_name = "test"
    environment  = "prd"
  }

  assert {
    condition     = aws_launch_template.main.name == "test-prd-launch-template"
    error_message = "Environment 'prd' should be valid"
  }
}

run "environment_valid_rls" {
  command = plan

  variables {
    project_name = "test"
    environment  = "rls"
  }

  assert {
    condition     = aws_launch_template.main.name == "test-rls-launch-template"
    error_message = "Environment 'rls' should be valid"
  }
}

run "environment_valid_stg" {
  command = plan

  variables {
    project_name = "test"
    environment  = "stg"
  }

  assert {
    condition     = aws_launch_template.main.name == "test-stg-launch-template"
    error_message = "Environment 'stg' should be valid"
  }
}

run "environment_valid_dev" {
  command = plan

  variables {
    project_name = "test"
    environment  = "dev"
  }

  assert {
    condition     = aws_launch_template.main.name == "test-dev-launch-template"
    error_message = "Environment 'dev' should be valid"
  }
}

# Test 2: 環境名の無効値テスト - 異常ケース
run "environment_invalid_value" {
  command = plan

  variables {
    project_name = "test"
    environment  = "invalid"
  }

  expect_failures = [
    var.environment,
  ]
}

run "environment_invalid_production" {
  command = plan

  variables {
    project_name = "test"
    environment  = "production"
  }

  expect_failures = [
    var.environment,
  ]
}

# Test 3: インスタンスタイプの検証
run "instance_type_t3_micro" {
  command = plan

  variables {
    project_name  = "test"
    environment   = "dev"
    instance_type = "t3.micro"
  }

  assert {
    condition     = aws_launch_template.main.instance_type == "t3.micro"
    error_message = "Instance type t3.micro should be valid"
  }
}

run "instance_type_t3_small" {
  command = plan

  variables {
    project_name  = "test"
    environment   = "dev"
    instance_type = "t3.small"
  }

  assert {
    condition     = aws_launch_template.main.instance_type == "t3.small"
    error_message = "Instance type t3.small should be valid"
  }
}

run "instance_type_m5_large" {
  command = plan

  variables {
    project_name  = "test"
    environment   = "dev"
    instance_type = "m5.large"
  }

  assert {
    condition     = aws_launch_template.main.instance_type == "m5.large"
    error_message = "Instance type m5.large should be valid"
  }
}

# Test 4: ボリュームサイズの制約テスト
run "volume_size_minimum" {
  command = plan

  variables {
    project_name = "test"
    environment  = "dev"
    volume_size  = 8
  }

  assert {
    condition     = aws_launch_template.main.block_device_mappings[0].ebs[0].volume_size == 8
    error_message = "Volume size 8 GB should be valid"
  }
}

run "volume_size_standard" {
  command = plan

  variables {
    project_name = "test"
    environment  = "dev"
    volume_size  = 20
  }

  assert {
    condition     = aws_launch_template.main.block_device_mappings[0].ebs[0].volume_size == 20
    error_message = "Volume size 20 GB should be valid"
  }
}

run "volume_size_large" {
  command = plan

  variables {
    project_name = "test"
    environment  = "dev"
    volume_size  = 100
  }

  assert {
    condition     = aws_launch_template.main.block_device_mappings[0].ebs[0].volume_size == 100
    error_message = "Volume size 100 GB should be valid"
  }
}

# Test 5: ボリュームタイプの検証
run "volume_type_gp3" {
  command = plan

  variables {
    project_name = "test"
    environment  = "dev"
    volume_type  = "gp3"
  }

  assert {
    condition     = aws_launch_template.main.block_device_mappings[0].ebs[0].volume_type == "gp3"
    error_message = "Volume type gp3 should be valid"
  }
}

run "volume_type_gp2" {
  command = plan

  variables {
    project_name = "test"
    environment  = "dev"
    volume_type  = "gp2"
  }

  assert {
    condition     = aws_launch_template.main.block_device_mappings[0].ebs[0].volume_type == "gp2"
    error_message = "Volume type gp2 should be valid"
  }
}

run "volume_type_io1" {
  command = plan

  variables {
    project_name = "test"
    environment  = "dev"
    volume_type  = "io1"
  }

  assert {
    condition     = aws_launch_template.main.block_device_mappings[0].ebs[0].volume_type == "io1"
    error_message = "Volume type io1 should be valid"
  }
}

# Test 6: SSH CIDR ブロックの検証
run "ssh_cidr_blocks_private" {
  command = plan

  variables {
    project_name    = "test"
    environment     = "dev"
    ssh_cidr_blocks = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  }

  assert {
    condition     = length([for rule in aws_security_group.main.ingress : rule if rule.from_port == 22 && contains(rule.cidr_blocks, "10.0.0.0/8")]) > 0
    error_message = "SSH should be allowed from private network 10.0.0.0/8"
  }

  assert {
    condition     = length([for rule in aws_security_group.main.ingress : rule if rule.from_port == 22 && contains(rule.cidr_blocks, "172.16.0.0/12")]) > 0
    error_message = "SSH should be allowed from private network 172.16.0.0/12"
  }

  assert {
    condition     = length([for rule in aws_security_group.main.ingress : rule if rule.from_port == 22 && contains(rule.cidr_blocks, "192.168.0.0/16")]) > 0
    error_message = "SSH should be allowed from private network 192.168.0.0/16"
  }
}

run "ssh_cidr_blocks_empty" {
  command = plan

  variables {
    project_name    = "test"
    environment     = "dev"
    ssh_cidr_blocks = []
  }

  assert {
    condition     = length([for rule in aws_security_group.main.ingress : rule if rule.from_port == 22]) == 0
    error_message = "SSH should not be allowed when CIDR blocks are empty"
  }
}

# Test 7: Mackerel 設定の検証
run "mackerel_api_key_validation" {
  command = plan

  variables {
    project_name           = "test"
    environment            = "dev"
    mackerel_api_key       = "test-api-key-123"
    mackerel_organization  = "test-org"
    mackerel_roles         = "web,api"
    create_parameter_store = true
  }

  assert {
    condition     = aws_ssm_parameter.mackerel_api_key[0].name == "/test/dev/mackerel/api_key"
    error_message = "Mackerel API key parameter should be created with correct name"
  }

  assert {
    condition     = aws_ssm_parameter.mackerel_organization[0].name == "/test/dev/mackerel/organization"
    error_message = "Mackerel organization parameter should be created with correct name"
  }

  assert {
    condition     = aws_ssm_parameter.mackerel_roles[0].name == "/test/dev/mackerel/roles"
    error_message = "Mackerel roles parameter should be created with correct name"
  }

  assert {
    condition     = output.effective_mackerel_settings.roles == "web,api"
    error_message = "Effective Mackerel roles should be web,api"
  }
}

run "mackerel_default_settings" {
  command = plan

  variables {
    project_name             = "test"
    environment              = "dev"
    mackerel_default_api_key = "default-api-key"
    mackerel_default_roles   = ["default", "test"]
  }

  assert {
    condition     = output.effective_mackerel_settings.api_key == "***設定済み***"
    error_message = "Effective Mackerel API key should be set"
  }

  assert {
    condition     = output.effective_mackerel_settings.display_name == "test-dev"
    error_message = "Default Mackerel display name should be project-environment"
  }

  assert {
    condition     = output.effective_mackerel_settings.roles == "default,test"
    error_message = "Default Mackerel roles should be default,test"
  }
}

# Test 8: CloudWatch 設定の検証
run "cloudwatch_default_namespace" {
  command = plan

  variables {
    project_name                 = "test"
    environment                  = "dev"
    cloudwatch_default_namespace = "Test/Namespace"
  }

  assert {
    condition     = output.effective_cloudwatch_settings.namespace == "Test/Namespace"
    error_message = "CloudWatch namespace should be Test/Namespace"
  }
}

run "cloudwatch_metrics_collection_interval" {
  command = plan

  variables {
    project_name                           = "test"
    environment                            = "dev"
    cloudwatch_metrics_collection_interval = 30
  }

  assert {
    condition     = output.effective_cloudwatch_settings.collection_interval == 30
    error_message = "CloudWatch collection interval should be 30"
  }
}

run "cloudwatch_cpu_metrics_validation" {
  command = plan

  variables {
    project_name = "test"
    environment  = "dev"
    cloudwatch_cpu_metrics = {
      measurement                 = ["cpu_usage_idle", "cpu_usage_user"]
      metrics_collection_interval = 30
      totalcpu                    = true
    }
  }

  assert {
    condition     = output.effective_cloudwatch_settings.collection_interval == 60
    error_message = "CloudWatch collection interval should be 60 (global setting)"
  }
}

# Test 9: カスタムパラメータプレフィックスの検証
run "custom_parameter_prefix" {
  command = plan

  variables {
    project_name              = "test"
    environment               = "dev"
    mackerel_parameter_prefix = "/custom/prefix/mackerel/"
    mackerel_api_key          = "test-api-key"
    create_parameter_store    = true
  }

  assert {
    condition     = aws_ssm_parameter.mackerel_api_key[0].name == "/custom/prefix/mackerel/api_key"
    error_message = "Mackerel API key should use custom parameter prefix"
  }

  assert {
    condition     = output.mackerel_parameter_prefix == "/custom/prefix/mackerel/"
    error_message = "Output parameter prefix should be custom"
  }
}

# Test 10: パラメータストア無効化の検証
run "parameter_store_disabled" {
  command = plan

  variables {
    project_name           = "test"
    environment            = "dev"
    mackerel_api_key       = "test-api-key"
    create_parameter_store = false
  }

  assert {
    condition     = length([for p in aws_ssm_parameter.mackerel_api_key : p]) == 0
    error_message = "Mackerel API key parameter should not be created when parameter store is disabled"
  }

  assert {
    condition     = length(output.parameter_store_names) == 0
    error_message = "Parameter store names should be empty when parameter store is disabled"
  }
}

# Test 11: 複雑なタグ検証
run "complex_tag_validation" {
  command = plan

  variables {
    project_name        = "test"
    environment         = "dev"
    app                 = "complex-app"
    owner_team          = "platform"
    owner_email         = "platform@example.com"
    cost_center         = "12345"
    billing_code        = "PROJ-2024-TEST"
    schedule            = "business-hours"
    backup_required     = true
    monitoring_level    = "enhanced"
    data_classification = "confidential"
    common_tags = {
      "CustomTag1" = "CustomValue1"
      "CustomTag2" = "CustomValue2"
    }
  }

  assert {
    condition     = aws_launch_template.main.tags["Owner"] == "platform"
    error_message = "Owner tag should be platform"
  }

  assert {
    condition     = aws_launch_template.main.tags["OwnerEmail"] == "platform@example.com"
    error_message = "OwnerEmail tag should be platform@example.com"
  }

  assert {
    condition     = aws_launch_template.main.tags["CostCenter"] == "12345"
    error_message = "CostCenter tag should be 12345"
  }

  assert {
    condition     = aws_launch_template.main.tags["BillingCode"] == "PROJ-2024-TEST"
    error_message = "BillingCode tag should be PROJ-2024-TEST"
  }

  assert {
    condition     = aws_launch_template.main.tags["Schedule"] == "business-hours"
    error_message = "Schedule tag should be business-hours"
  }

  assert {
    condition     = aws_launch_template.main.tags["BackupRequired"] == "yes"
    error_message = "BackupRequired tag should be yes"
  }

  assert {
    condition     = aws_launch_template.main.tags["MonitoringLevel"] == "enhanced"
    error_message = "MonitoringLevel tag should be enhanced"
  }

  assert {
    condition     = aws_launch_template.main.tags["DataClassification"] == "confidential"
    error_message = "DataClassification tag should be confidential"
  }

  assert {
    condition     = aws_launch_template.main.tags["CustomTag1"] == "CustomValue1"
    error_message = "CustomTag1 should be CustomValue1"
  }

  assert {
    condition     = aws_launch_template.main.tags["CustomTag2"] == "CustomValue2"
    error_message = "CustomTag2 should be CustomValue2"
  }
}

# Test 12: AMI 名フィルターの検証
run "ami_name_filter_validation" {
  command = plan

  variables {
    project_name    = "test"
    environment     = "dev"
    ami_name_filter = ["amzn2023-ami-ecs-*", "amzn2023-ami-minimal-*"]
  }

  assert {
    condition     = data.aws_ami.amazon_linux.most_recent == true
    error_message = "AMI should be the most recent version"
  }

  assert {
    condition     = contains(data.aws_ami.amazon_linux.owners, "amazon")
    error_message = "AMI should be owned by Amazon"
  }
}

# Test 13: キーペア名の検証
run "key_name_validation" {
  command = plan

  variables {
    project_name = "test"
    environment  = "dev"
    key_name     = "my-custom-key"
  }

  assert {
    condition     = aws_launch_template.main.key_name == "my-custom-key"
    error_message = "Launch Template should use custom key name"
  }
}

run "key_name_empty" {
  command = plan

  variables {
    project_name = "test"
    environment  = "dev"
    key_name     = ""
  }

  assert {
    condition     = aws_launch_template.main.key_name == null
    error_message = "Launch Template should not have key name when empty"
  }
}

# Test 14: IAM インスタンスプロファイルの検証
run "iam_instance_profile_validation" {
  command = plan

  variables {
    project_name              = "test"
    environment               = "dev"
    iam_instance_profile_name = "custom-instance-profile"
  }

  assert {
    condition     = aws_launch_template.main.iam_instance_profile[0].name == "custom-instance-profile"
    error_message = "IAM instance profile should be custom-instance-profile"
  }
}

run "iam_instance_profile_empty" {
  command = plan

  variables {
    project_name              = "test"
    environment               = "dev"
    iam_instance_profile_name = ""
  }

  assert {
    condition     = length(aws_launch_template.main.iam_instance_profile) == 0
    error_message = "IAM instance profile should not be set when empty"
  }
}

# Test 15: パブリックIP設定の検証
run "associate_public_ip_true" {
  command = plan

  variables {
    project_name        = "test"
    environment         = "dev"
    associate_public_ip = true
  }

  assert {
    condition     = aws_launch_template.main.network_interfaces[0].associate_public_ip_address == true
    error_message = "Public IP should be associated when set to true"
  }
}

run "associate_public_ip_false" {
  command = plan

  variables {
    project_name        = "test"
    environment         = "dev"
    associate_public_ip = false
  }

  assert {
    condition     = aws_launch_template.main.network_interfaces[0].associate_public_ip_address == false
    error_message = "Public IP should not be associated when set to false"
  }
}
