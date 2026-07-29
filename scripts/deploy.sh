#!/usr/bin/env bash
set -euo pipefail

# Wrapper script to init, plan, and apply Terraform per environment
# Usage: ./scripts/deploy.sh <dev|staging|prod> [region] [auto-approve]

ENVIRONMENT="${1:-}"
REGION="${2:-us-east-1}"
AUTO_APPROVE="${3:-false}"
DYNAMODB_TABLE="terraform-state-lock"

if [ -z "${ENVIRONMENT}" ]; then
  echo "Error: Environment parameter required."
  echo "Usage: $0 <dev|staging|prod> [region] [auto-approve]"
  exit 1
fi

if [[ ! "${ENVIRONMENT}" =~ ^(dev|staging|prod)$ ]]; then
  echo "Error: Invalid environment '${ENVIRONMENT}'. Must be one of: dev, staging, prod."
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ENV_DIR="${ROOT_DIR}/environments/${ENVIRONMENT}"

if [ ! -d "${ENV_DIR}" ]; then
  echo "Error: Environment directory '${ENV_DIR}' not found."
  exit 1
fi

echo "=================================================="
echo " Deploying Environment: ${ENVIRONMENT}"
echo " Region:                ${REGION}"
echo " Directory:             ${ENV_DIR}"
echo "=================================================="

# Get AWS Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
BUCKET_NAME="tfstate-${AWS_ACCOUNT_ID}-${REGION}"

echo "Using Remote State Bucket: ${BUCKET_NAME}"

cd "${ENV_DIR}"

echo "--> Initializing Terraform..."
terraform init \
  -backend-config="bucket=${BUCKET_NAME}" \
  -backend-config="region=${REGION}" \
  -backend-config="dynamodb_table=${DYNAMODB_TABLE}" \
  -backend-config="key=${ENVIRONMENT}/terraform.tfstate" \
  -reconfigure

echo "--> Validating Terraform configuration..."
terraform validate

echo "--> Generating Terraform Execution Plan..."
terraform plan -out="${ENVIRONMENT}.tfplan"

if [ "${AUTO_APPROVE}" = "true" ] || [ "${AUTO_APPROVE}" = "-auto-approve" ]; then
  echo "--> Auto-approving execution plan..."
  terraform apply -auto-approve "${ENVIRONMENT}.tfplan"
else
  read -p "Do you want to apply this plan to environment '${ENVIRONMENT}'? (yes/no): " CONFIRM
  if [ "${CONFIRM}" = "yes" ]; then
    echo "--> Applying Terraform changes..."
    terraform apply "${ENVIRONMENT}.tfplan"
  else
    echo "Apply cancelled."
    exit 0
  fi
fi

rm -f "${ENVIRONMENT}.tfplan"
echo "=== Deployment Completed Successfully for ${ENVIRONMENT} ==="
