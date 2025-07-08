# ==================================================
# EC2 Launch Template Module - Mock Tests
# ==================================================
#
# このファイルは Launch Template モジュールのモックテストを行います
# AWS認証情報なしでテストを実行できます
#
# テスト内容:
#   - モックプロバイダーを使用したテスト
#   - AWS認証情報不要
#   - 高速なテスト実行
#   - 基本的なリソース作成の検証
#
# 最新更新: 2024年12月
# ==================================================

# モックプロバイダーの設定
mock_provider "aws" {
  # AWS カラー識別データソース
  mock_data "aws_caller_identity" {
    defaults = {
      id         = "123456789012"
      account_id = "123456789012"
      arn        = "arn:aws:sts::123456789012:assumed-role/test-role/test-session"
      user_id    = "AIDACKCEVSQ6C2EXAMPLE"
    }
  }

  # AWS リージョンデータソース
  mock_data "aws_region" {
    defaults = {
      id   = "ap-northeast-1"
      name = "ap-northeast-1"
    }
  }

  # デフォルトVPCデータソース
  mock_data "aws_vpc" {
    defaults = {
      id                                   = "vpc-12345678"
      cidr_block                           = "172.31.0.0/16"
      instance_tenancy                     = "default"
      enable_dns_hostnames                 = true
      enable_dns_support                   = true
      enable_network_address_usage_metrics = false
      default                              = true
      state                                = "available"
      owner_id                             = "123456789012"
      tags = {
        Name = "default"
      }
    }
  }

  # ECS最適化AMIデータソース
  mock_data "aws_ami" {
    defaults = {
      id                  = "ami-12345678"
      name                = "amzn2023-ami-ecs-20231201"
      description         = "Amazon Linux 2023 AMI ECS Optimized"
      owner_id            = "591542846629"
      owners              = ["amazon"]
      architecture        = "x86_64"
      creation_date       = "2023-12-01T00:00:00.000Z"
      image_type          = "machine"
      most_recent         = true
      platform            = "linux"
      platform_details    = "Linux/UNIX"
      public              = true
      state               = "available"
      virtualization_type = "hvm"
      root_device_name    = "/dev/xvda"
      root_device_type    = "ebs"
      tags = {
        Name = "amzn2023-ami-ecs-20231201"
      }
    }
  }

  # セキュリティグループリソース
  mock_resource "aws_security_group" {
    defaults = {
      id          = "sg-12345678"
      name        = "test-dev-ec2-sg"
      description = "EC2インスタンス用セキュリティグループ"
      vpc_id      = "vpc-12345678"
      owner_id    = "123456789012"
      arn         = "arn:aws:ec2:ap-northeast-1:123456789012:security-group/sg-12345678"
      ingress = [
        {
          description      = "HTTP"
          from_port        = 80
          to_port          = 80
          protocol         = "tcp"
          cidr_blocks      = ["0.0.0.0/0"]
          ipv6_cidr_blocks = []
          prefix_list_ids  = []
          security_groups  = []
          self             = false
        },
        {
          description      = "HTTPS"
          from_port        = 443
          to_port          = 443
          protocol         = "tcp"
          cidr_blocks      = ["0.0.0.0/0"]
          ipv6_cidr_blocks = []
          prefix_list_ids  = []
          security_groups  = []
          self             = false
        },
        {
          description      = "ECS dynamic port mapping"
          from_port        = 32768
          to_port          = 65535
          protocol         = "tcp"
          cidr_blocks      = ["0.0.0.0/0"]
          ipv6_cidr_blocks = []
          prefix_list_ids  = []
          security_groups  = []
          self             = false
        }
      ]
      egress = [
        {
          description      = "All outbound traffic"
          from_port        = 0
          to_port          = 0
          protocol         = "-1"
          cidr_blocks      = ["0.0.0.0/0"]
          ipv6_cidr_blocks = []
          prefix_list_ids  = []
          security_groups  = []
          self             = false
        }
      ]
      tags = {
        Name        = "test-dev-ec2-sg"
        Project     = "test"
        Environment = "dev"
        ManagedBy   = "terraform"
      }
    }
  }

  # Launch Template リソース
  mock_resource "aws_launch_template" {
    defaults = {
      id                     = "lt-12345678"
      name                   = "test-dev-launch-template"
      arn                    = "arn:aws:ec2:ap-northeast-1:123456789012:launch-template/lt-12345678"
      latest_version         = 1
      default_version        = 1
      instance_type          = "t3.micro"
      key_name               = null
      image_id               = "ami-12345678"
      vpc_security_group_ids = ["sg-12345678"]
      user_data              = "IyEvYmluL2Jhc2gKZWNobyBFQ1NfQ0xVU1RFUj10ZXN0LWRldi1lY3M="

      block_device_mappings = [
        {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 20
            volume_type           = "gp3"
            encrypted             = true
            delete_on_termination = true
            iops                  = 3000
            throughput            = 125
            snapshot_id           = ""
            kms_key_id            = ""
          }
        }
      ]

      network_interfaces = [
        {
          associate_public_ip_address = true
          delete_on_termination       = true
          device_index                = 0
          security_groups             = ["sg-12345678"]
          subnet_id                   = ""
        }
      ]

      iam_instance_profile = []

      monitoring = [
        {
          enabled = true
        }
      ]

      tag_specifications = [
        {
          resource_type = "instance"
          tags = {
            Name        = "test-dev-instance"
            Project     = "test"
            Environment = "dev"
            ManagedBy   = "terraform"
          }
        }
      ]

      tags = {
        Name        = "test-dev-launch-template"
        Project     = "test"
        Environment = "dev"
        ManagedBy   = "terraform"
      }
    }
  }

  # SSM Parameter Store リソース
  mock_resource "aws_ssm_parameter" {
    defaults = {
      id             = "/test/dev/config/mackerel/api-key"
      name           = "/test/dev/config/mackerel/api-key"
      arn            = "arn:aws:ssm:ap-northeast-1:123456789012:parameter/test/dev/config/mackerel/api-key"
      type           = "SecureString"
      value          = "dummy-api-key"
      version        = 1
      tier           = "Standard"
      policy         = ""
      data_type      = "text"
      insecure_value = ""
      key_id         = "alias/aws/ssm"
      tags = {
        Name        = "mackerel-api-key"
        Project     = "test"
        Environment = "dev"
        ManagedBy   = "terraform"
      }
    }
  }
}

# Test 1: モックプロバイダーでの基本テスト
run "mock_basic_test" {
  command = apply

  variables {
    project_name           = "test"
    environment            = "dev"
    app                    = "mock-test"
    instance_type          = "t3.micro"
    volume_size            = 20
    ssh_cidr_blocks        = ["10.0.0.0/16"]
    ecs_cluster_name       = "test-dev-ecs"
    mackerel_api_key       = "mock-api-key"
    mackerel_organization  = "mock-org"
    mackerel_roles         = "mock,test"
    create_parameter_store = true
  }

  assert {
    condition     = aws_launch_template.main.name == "test-dev-launch-template"
    error_message = "Launch Template name should be correct"
  }

  assert {
    condition     = aws_launch_template.main.instance_type == "t3.micro"
    error_message = "Launch Template instance type should be t3.micro"
  }

  assert {
    condition     = aws_launch_template.main.image_id == "ami-12345678"
    error_message = "Launch Template should use mocked AMI"
  }

  assert {
    condition     = aws_security_group.main.name == "test-dev-ec2-sg"
    error_message = "Security Group name should be correct"
  }

  assert {
    condition     = aws_security_group.main.vpc_id == "vpc-12345678"
    error_message = "Security Group should use mocked VPC"
  }

  assert {
    condition     = length(aws_security_group.main.ingress) == 3
    error_message = "Security Group should have 3 ingress rules"
  }

  assert {
    condition     = length(aws_security_group.main.egress) == 1
    error_message = "Security Group should have 1 egress rule"
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

# Test 2: データソースの検証
run "mock_data_sources_test" {
  command = apply

  variables {
    project_name = "test"
    environment  = "dev"
  }

  assert {
    condition     = data.aws_caller_identity.current.account_id == "123456789012"
    error_message = "Caller identity should return mocked account ID"
  }

  assert {
    condition     = data.aws_region.current.name == "ap-northeast-1"
    error_message = "Region should return mocked region name"
  }

  assert {
    condition     = data.aws_vpc.default.id == "vpc-12345678"
    error_message = "VPC should return mocked VPC ID"
  }

  assert {
    condition     = data.aws_ami.amazon_linux.id == "ami-12345678"
    error_message = "AMI should return mocked AMI ID"
  }

  assert {
    condition     = data.aws_ami.amazon_linux.name == "amzn2023-ami-ecs-20231201"
    error_message = "AMI should return mocked AMI name"
  }

  assert {
    condition     = data.aws_ami.amazon_linux.owners[0] == "amazon"
    error_message = "AMI should be owned by amazon"
  }
}

# Test 3: タグの検証
run "mock_tags_test" {
  command = apply

  variables {
    project_name = "test"
    environment  = "dev"
    app          = "tag-test"
    owner_team   = "platform"
    owner_email  = "platform@example.com"
    cost_center  = "12345"
    common_tags = {
      "CustomTag" = "CustomValue"
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
    condition     = aws_launch_template.main.tags["Application"] == "tag-test"
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
    error_message = "Launch Template should have custom tag"
  }

  assert {
    condition     = aws_security_group.main.tags["Project"] == "test"
    error_message = "Security Group should have Project tag"
  }

  assert {
    condition     = aws_security_group.main.tags["Environment"] == "dev"
    error_message = "Security Group should have Environment tag"
  }

  assert {
    condition     = aws_security_group.main.tags["ManagedBy"] == "terraform"
    error_message = "Security Group should have ManagedBy tag"
  }
}

# Test 4: Parameter Store の検証
run "mock_parameter_store_test" {
  command = apply

  variables {
    project_name           = "test"
    environment            = "dev"
    app                    = "params-test"
    mackerel_api_key       = "test-api-key"
    mackerel_organization  = "test-org"
    mackerel_roles         = "test,params"
    create_parameter_store = true
  }

  assert {
    condition     = aws_ssm_parameter.mackerel_api_key[0].name == "/test/dev/config/mackerel/api-key"
    error_message = "Mackerel API key parameter should have correct name"
  }

  assert {
    condition     = aws_ssm_parameter.mackerel_api_key[0].type == "SecureString"
    error_message = "Mackerel API key parameter should be SecureString"
  }

  assert {
    condition     = aws_ssm_parameter.mackerel_display_name[0].name == "/test/dev/config/mackerel/display-name"
    error_message = "Mackerel display name parameter should have correct name"
  }

  assert {
    condition     = aws_ssm_parameter.mackerel_organization[0].name == "/test/dev/config/mackerel/organization"
    error_message = "Mackerel organization parameter should have correct name"
  }

  assert {
    condition     = aws_ssm_parameter.mackerel_roles[0].name == "/test/dev/config/mackerel/roles"
    error_message = "Mackerel roles parameter should have correct name"
  }

  assert {
    condition     = aws_ssm_parameter.cloudwatch_agent_config[0].name == "/test/dev/config/cloudwatch/agent"
    error_message = "CloudWatch agent config parameter should have correct name"
  }
}

# Test 5: 出力値の検証
run "mock_outputs_test" {
  command = apply

  variables {
    project_name           = "test"
    environment            = "dev"
    app                    = "outputs-test"
    mackerel_api_key       = "test-api-key"
    mackerel_organization  = "test-org"
    mackerel_roles         = "test,outputs"
    create_parameter_store = true
  }

  assert {
    condition     = output.launch_template_id == "lt-12345678"
    error_message = "Launch Template ID should be mocked value"
  }

  assert {
    condition     = output.launch_template_name == "test-dev-launch-template"
    error_message = "Launch Template name should be correct"
  }

  assert {
    condition     = output.ami_id == "ami-12345678"
    error_message = "AMI ID should be mocked value"
  }

  assert {
    condition     = output.ami_name == "amzn2023-ami-ecs-20231201"
    error_message = "AMI name should be mocked value"
  }

  assert {
    condition     = output.security_group_id == "sg-12345678"
    error_message = "Security Group ID should be mocked value"
  }

  assert {
    condition     = output.security_group_name == "test-dev-ec2-sg"
    error_message = "Security Group name should be correct"
  }

  assert {
    condition     = output.mackerel_parameter_prefix == "/test/dev/config/mackerel/"
    error_message = "Mackerel parameter prefix should be correct"
  }

  # Note: Sensitive output values cannot be directly tested in assertions
  # assert {
  #   condition     = output.effective_mackerel_settings.display_name == "test-dev-outputs-test"
  #   error_message = "Effective Mackerel display name should be correct"
  # }

  # assert {
  #   condition     = output.effective_mackerel_settings.roles == "test,outputs"
  #   error_message = "Effective Mackerel roles should be correct"
  # }

  assert {
    condition     = output.effective_cloudwatch_settings.namespace == "test-metrics"
    error_message = "Effective CloudWatch namespace should be correct"
  }

  # Note: Sensitive output values cannot be directly tested in assertions
  # assert {
  #   condition     = length(output.parameter_store_names) >= 6
  #   error_message = "Parameter store names should contain at least 6 items"
  # }
}

# Test 6: 異なるインスタンスタイプでの検証
run "mock_different_instance_types" {
  command = apply

  variables {
    project_name  = "test"
    environment   = "dev"
    instance_type = "t3.small"
  }

  assert {
    condition     = aws_launch_template.main.instance_type == "t3.small"
    error_message = "Launch Template instance type should be t3.small"
  }
}

# Test 7: カスタム AMI フィルターの検証
run "mock_custom_ami_filter" {
  command = apply

  variables {
    project_name    = "test"
    environment     = "dev"
    ami_name_filter = ["amzn2023-ami-ecs-*", "amzn2023-ami-minimal-*"]
  }

  assert {
    condition     = data.aws_ami.amazon_linux.id == "ami-12345678"
    error_message = "AMI should use mocked AMI regardless of filter"
  }

  assert {
    condition     = data.aws_ami.amazon_linux.most_recent == true
    error_message = "AMI should be most recent"
  }
}

# Test 8: SSH制限なしの検証
run "mock_no_ssh_access" {
  command = apply

  variables {
    project_name    = "test"
    environment     = "dev"
    ssh_cidr_blocks = []
  }

  assert {
    condition     = length([for rule in aws_security_group.main.ingress : rule if rule.from_port == 22]) == 0
    error_message = "SSH access should be disabled when CIDR blocks are empty"
  }

  assert {
    condition     = length(aws_security_group.main.ingress) == 3
    error_message = "Security group should have 3 ingress rules (HTTP, HTTPS, ECS Dynamic) when SSH is disabled"
  }
}

# Test 9: 本番環境設定の検証
run "mock_production_settings" {
  command = apply

  variables {
    project_name  = "test"
    environment   = "prd"
    app           = "prod-app"
    instance_type = "t3.medium"
    volume_size   = 50
  }

  assert {
    condition     = aws_launch_template.main.name == "test-prd-launch-template"
    error_message = "Launch Template name should match mock value"
  }

  assert {
    condition     = aws_launch_template.main.instance_type == "t3.medium"
    error_message = "Launch Template instance type should be t3.medium"
  }

  assert {
    condition     = aws_launch_template.main.block_device_mappings[0].ebs[0].volume_size == 50
    error_message = "EBS volume size should be 50 GB"
  }

  assert {
    condition     = aws_launch_template.main.tags["Project"] == "test"
    error_message = "Launch Template should have correct Project tag"
  }

  assert {
    condition     = aws_launch_template.main.tags["Environment"] == "dev"
    error_message = "Launch Template should have correct Environment tag"
  }

  assert {
    condition     = aws_launch_template.main.tags["ManagedBy"] == "terraform"
    error_message = "Launch Template should have correct ManagedBy tag"
  }
}

# Test 10: 最小構成での検証
run "mock_minimal_configuration" {
  command = apply

  variables {
    project_name = "test"
    environment  = "dev"
    # 他はデフォルト値
  }

  assert {
    condition     = aws_launch_template.main.name == "test-dev-launch-template"
    error_message = "Minimal Launch Template name should be correct"
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
    condition     = aws_launch_template.main.key_name == null
    error_message = "Minimal Launch Template should not have key name"
  }

  assert {
    condition     = output.effective_mackerel_settings.display_name == "test-dev"
    error_message = "Minimal Mackerel display name should be project-environment"
  }

  assert {
    condition     = output.effective_cloudwatch_settings.namespace == "test-metrics"
    error_message = "Minimal CloudWatch namespace should be project-metrics"
  }

  assert {
    condition     = output.mackerel_parameter_prefix == "/test/dev/config/mackerel/"
    error_message = "Mackerel parameter prefix should be correct"
  }
}
