#!/bin/bash

# Terraformで作成されたリソースを検索するスクリプト
# 使用方法: ./search_terraform_resources.sh [project_name] [environment]

set -e

# 色付きoutput用
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# パラメータ
PROJECT_NAME=${1:-""}
ENVIRONMENT=${2:-""}

echo -e "${BLUE}=== Terraformで作成されたリソース検索 ===${NC}"
echo "検索条件:"
echo "- ManagedBy: terraform"
if [ -n "$PROJECT_NAME" ]; then
    echo "- Project: $PROJECT_NAME"
fi
if [ -n "$ENVIRONMENT" ]; then
    echo "- Environment: $ENVIRONMENT"
fi
echo

# タグフィルタの構築
TAG_FILTERS="Key=ManagedBy,Values=terraform"
if [ -n "$PROJECT_NAME" ]; then
    TAG_FILTERS="$TAG_FILTERS Key=Project,Values=$PROJECT_NAME"
fi
if [ -n "$ENVIRONMENT" ]; then
    TAG_FILTERS="$TAG_FILTERS Key=Environment,Values=$ENVIRONMENT"
fi

# すべてのリソースを検索
echo -e "${YELLOW}=== 全リソース検索 ===${NC}"
aws resourcegroupstaggingapi get-resources \
    --tag-filters $TAG_FILTERS \
    --query 'ResourceTagMappingList[].[ResourceARN, Tags[?Key==`Name`].Value|[0] || `N/A`]' \
    --output table

# リソースタイプ別のカウント
echo -e "${YELLOW}=== リソースタイプ別集計 ===${NC}"
aws resourcegroupstaggingapi get-resources \
    --tag-filters $TAG_FILTERS \
    --query 'ResourceTagMappingList[].ResourceARN' \
    --output text | \
    sed 's/.*:\([^:]*\):.*/\1/' | \
    sort | uniq -c | sort -nr

# 特定のリソースタイプの詳細
echo -e "${YELLOW}=== EC2インスタンス詳細 ===${NC}"
aws resourcegroupstaggingapi get-resources \
    --tag-filters $TAG_FILTERS \
    --resource-type-filters EC2:Instance \
    --query 'ResourceTagMappingList[].[ResourceARN, Tags[?Key==`Name`].Value|[0] || `N/A`]' \
    --output table

echo -e "${YELLOW}=== S3バケット詳細 ===${NC}"
aws resourcegroupstaggingapi get-resources \
    --tag-filters $TAG_FILTERS \
    --resource-type-filters S3:Bucket \
    --query 'ResourceTagMappingList[].[ResourceARN, Tags[?Key==`Name`].Value|[0] || `N/A`]' \
    --output table

echo -e "${YELLOW}=== Auto Scaling Group詳細 ===${NC}"
aws resourcegroupstaggingapi get-resources \
    --tag-filters $TAG_FILTERS \
    --resource-type-filters AutoScaling:AutoScalingGroup \
    --query 'ResourceTagMappingList[].[ResourceARN, Tags[?Key==`Name`].Value|[0] || `N/A`]' \
    --output table

# コスト情報（直近30日）
echo -e "${YELLOW}=== コスト情報（直近30日） ===${NC}"
START_DATE=$(date -d "30 days ago" +%Y-%m-%d)
END_DATE=$(date +%Y-%m-%d)

if [ -n "$PROJECT_NAME" ] && [ -n "$ENVIRONMENT" ]; then
    aws ce get-cost-and-usage \
        --time-period Start=$START_DATE,End=$END_DATE \
        --group-by Type=TAG,Key=Project Type=TAG,Key=Environment \
        --granularity MONTHLY \
        --metrics BlendedCost \
        --filter '{
            "Tags": {
                "Key": "ManagedBy",
                "Values": ["terraform"]
            }
        }' \
        --query 'ResultsByTime[].Groups[].[Keys, Metrics.BlendedCost.Amount]' \
        --output table
fi

echo -e "${GREEN}検索完了${NC}"
