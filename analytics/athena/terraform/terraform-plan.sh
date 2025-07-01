#!/bin/bash

# AWS Account Confirmation Script for Terraform Plan
# This script ensures AWS account verification before running terraform plan

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo -e "${RED}🚨 AWS Account Confirmation Required! 🚨${NC}"
echo "=========================================="
echo ""

# Get AWS account information
echo "Retrieving AWS account information..."
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "unknown")
USER_ID=$(aws sts get-caller-identity --query UserId --output text 2>/dev/null || echo "unknown")
ARN=$(aws sts get-caller-identity --query Arn --output text 2>/dev/null || echo "unknown")

if [ "$ACCOUNT_ID" = "unknown" ] || [ "$USER_ID" = "unknown" ] || [ "$ARN" = "unknown" ]; then
    echo -e "${RED}❌ Error: Could not retrieve AWS account information.${NC}"
    echo "Please ensure your AWS credentials are configured correctly."
    echo "Run 'aws configure' or set AWS environment variables."
    exit 1
fi

echo ""
echo -e "${BLUE}Current AWS Account Information:${NC}"
echo -e "${BLUE}- Account ID: ${YELLOW}$ACCOUNT_ID${NC}"
echo -e "${BLUE}- User ID: ${YELLOW}$USER_ID${NC}"
echo -e "${BLUE}- ARN: ${YELLOW}$ARN${NC}"
echo ""
echo -e "${YELLOW}⚠️  Please verify this is the correct AWS account!${NC}"
echo ""

# Confirmation loop
while true; do
    echo -n "Do you want to proceed with this AWS account? (y/N): "
    read -r confirmation
    case "$confirmation" in
        [yY]|[yY][eE][sS])
            echo ""
            echo -e "${GREEN}✅ AWS account confirmed. Running terraform plan...${NC}"
            echo ""
            break
            ;;
        [nN]|[nN][oO]|"")
            echo ""
            echo -e "${RED}❌ Operation cancelled by user.${NC}"
            echo "Please configure the correct AWS credentials and try again."
            exit 1
            ;;
        *)
            echo "Please answer yes (y) or no (n)."
            ;;
    esac
done

# Run terraform plan
terraform plan "$@"

