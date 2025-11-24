#!/usr/bin/env bash
set -euo pipefail

# Script to bootstrap AWS Remote State resources (S3 bucket + DynamoDB table)
# Usage: ./scripts/bootstrap.sh <region>

REGION="${1:-us-east-1}"
DYNAMODB_TABLE_NAME="terraform-state-lock"

echo "=== Initializing Terraform Remote State Backend Bootstrap ==="
echo "Target Region: ${REGION}"

# Get AWS Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
if [ -z "${AWS_ACCOUNT_ID}" ]; then
  echo "Error: Unable to fetch AWS Account ID. Please verify your AWS CLI credentials."
  exit 1
fi

BUCKET_NAME="tfstate-${AWS_ACCOUNT_ID}-${REGION}"

echo "AWS Account ID: ${AWS_ACCOUNT_ID}"
echo "S3 Bucket Name: ${BUCKET_NAME}"
echo "DynamoDB Table Name: ${DYNAMODB_TABLE_NAME}"

# 1. Create S3 Bucket
if aws s3api head-bucket --bucket "${BUCKET_NAME}" 2>/dev/null; then
  echo "S3 bucket '${BUCKET_NAME}' already exists."
else
  echo "Creating S3 bucket '${BUCKET_NAME}'..."
  if [ "${REGION}" = "us-east-1" ]; then
    aws s3api create-bucket --bucket "${BUCKET_NAME}" --region "${REGION}"
  else
    aws s3api create-bucket --bucket "${BUCKET_NAME}" --region "${REGION}" \
      --create-bucket-configuration LocationConstraint="${REGION}"
  fi
  echo "S3 bucket created successfully."
fi

# Enable S3 Bucket Versioning
echo "Enabling versioning on S3 bucket..."
aws s3api put-bucket-versioning \
  --bucket "${BUCKET_NAME}" \
  --versioning-configuration Status=Enabled

# Enable Default Server-Side Encryption (AES256)
echo "Enabling AES256 server-side encryption..."
aws s3api put-bucket-encryption \
  --bucket "${BUCKET_NAME}" \
  --server-side-encryption-configuration '{
    "Rules": [
      {
        "ApplyServerSideEncryptionByDefault": {
          "SSEAlgorithm": "AES256"
        }
      }
    ]
  }'

# Enable Block Public Access
echo "Enabling Public Access Block on S3 bucket..."
aws s3api put-public-access-block \
  --bucket "${BUCKET_NAME}" \
  --public-access-block-configuration '{
    "BlockPublicAcls": true,
    "IgnorePublicAcls": true,
    "BlockPublicPolicy": true,
    "RestrictPublicBuckets": true
  }'

# 2. Create DynamoDB Table for State Locking
if aws dynamodb describe-table --table-name "${DYNAMODB_TABLE_NAME}" --region "${REGION}" >/dev/null 2>&1; then
  echo "DynamoDB table '${DYNAMODB_TABLE_NAME}' already exists."
else
  echo "Creating DynamoDB table '${DYNAMODB_TABLE_NAME}' for state locking..."
  aws dynamodb create-table \
    --table-name "${DYNAMODB_TABLE_NAME}" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "${REGION}"
  
  echo "Waiting for DynamoDB table to become ACTIVE..."
  aws dynamodb wait table-exists --table-name "${DYNAMODB_TABLE_NAME}" --region "${REGION}"
  echo "DynamoDB table created successfully."
fi

echo ""
echo "=== Bootstrap Completed Successfully ==="
echo "Use the following backend configuration details:"
echo "  Bucket:         ${BUCKET_NAME}"
echo "  DynamoDB Table: ${DYNAMODB_TABLE_NAME}"
echo "  Region:         ${REGION}"
