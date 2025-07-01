#!/bin/bash

echo ""
echo "🚨 AWS Account Confirmation Required! 🚨"
echo "=========================================="
echo ""
echo "Current AWS Account Information:"
echo "- Account ID: 386224109985"
echo "- User ID: AIDAVT3GAHGQ3HOASZGPH"
echo "- ARN: arn:aws:iam::386224109985:user/dh_y.ohi"
echo ""
echo "⚠️  Please verify this is the correct AWS account!"
echo ""

while true; do
  echo -n "Do you want to proceed with this AWS account? (y/n): "
  read -r answer
  case $answer in
    [Yy]* )
      echo "✅ AWS account confirmed. Running terraform apply..."
      terraform apply -var="aws_account_confirmed=true"
      break
      ;;
    [Nn]* )
      echo "❌ Operation cancelled by user."
      echo "Please configure the correct AWS credentials and try again."
      exit 1
      ;;
    * )
      echo "Please answer yes (y) or no (n)."
      ;;
  esac
done
