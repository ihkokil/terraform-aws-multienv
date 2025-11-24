#!/usr/bin/env bash
set -euo pipefail

# Wrapper script to destroy Terraform resources per environment
# Usage: ./scripts/destroy.sh <dev|staging|prod> [region] [auto-approve]

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
echo " DESTROYING Environment: ${ENVIRONMENT}"
echo " Region:                 ${REGION}"
echo " Directory:              ${ENV_DIR}"
echo "=================================================="

# Get AWS Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
BUCKET_NAME="tfstate-${AWS_ACCOUNT_ID}-${REGION}"

cd "${ENV_DIR}"

echo "--> Initializing Terraform..."
terraform init \
  -backend-config="bucket=${BUCKET_NAME}" \
  -backend-config="region=${REGION}" \
  -backend-config="dynamodb_table=${DYNAMODB_TABLE}" \
  -backend-config="key=${ENVIRONMENT}/terraform.tfstate" \
  -reconfigure

if [ "${AUTO_APPROVE}" = "true" ] || [ "${AUTO_APPROVE}" = "-auto-approve" ]; then
  echo "--> Auto-approving destroy action..."
  terraform destroy -auto-approve
else
  echo "WARNING: DESTROYING ALL RESOURCES IN ${ENVIRONMENT} ENVIRONMENT!"
  read -p "Are you sure you want to destroy infrastructure in '${ENVIRONMENT}'? Type '${ENVIRONMENT}' to confirm: " CONFIRM
  if [ "${CONFIRM}" = "${ENVIRONMENT}" ]; then
    echo "--> Destroying Terraform resources..."
    terraform destroy
  else
    echo "Destroy cancelled."
    exit 0
  fi
fi

echo "=== Destruction Completed for ${ENVIRONMENT} ==="
