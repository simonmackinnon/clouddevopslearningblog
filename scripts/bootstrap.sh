#!/usr/bin/env bash
# Bootstrap blog Terraform state bucket.
# Run this ONCE before the first terraform init/apply.
#
# Prerequisites:
#   - AWS CLI configured with admin credentials
#
# Usage: ./scripts/bootstrap.sh
set -euo pipefail

REGION="ap-southeast-2"
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
STATE_BUCKET="blog-terraform-state-${ACCOUNT}"

echo "Account : $ACCOUNT"
echo "Region  : $REGION"
echo "Bucket  : $STATE_BUCKET"
echo ""

# ─── Terraform state bucket ──────────────────────────────────────────────────
if aws s3api head-bucket --bucket "$STATE_BUCKET" 2>/dev/null; then
  echo "State bucket already exists — skipping"
else
  echo "Creating Terraform state bucket..."
  aws s3api create-bucket \
    --bucket "$STATE_BUCKET" \
    --region "$REGION" \
    --create-bucket-configuration LocationConstraint="$REGION" >/dev/null
  aws s3api put-bucket-versioning \
    --bucket "$STATE_BUCKET" \
    --versioning-configuration Status=Enabled
  aws s3api put-bucket-encryption \
    --bucket "$STATE_BUCKET" \
    --server-side-encryption-configuration \
    '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
  aws s3api put-public-access-block \
    --bucket "$STATE_BUCKET" \
    --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
  echo "State bucket created."
fi

echo ""
echo "─── Next steps ────────────────────────────────────────────────────────"
echo ""
echo "  cd infra"
echo "  terraform init -backend-config=\"bucket=${STATE_BUCKET}\""
echo "  terraform plan    # review — existing resources import, MX/SPF are new"
echo "  terraform apply"
echo ""
echo "After apply, go to https://improvmx.com and:"
echo "  1. Add domain: theclouddevopslearningblog.com"
echo "  2. Create alias: me@ → your-email@gmail.com"
echo "────────────────────────────────────────────────────────────────────────"
