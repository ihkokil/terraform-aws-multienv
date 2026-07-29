# Terraform Multi-Environment AWS Infrastructure (`terraform-aws-multienv`)

A production-ready, modular Terraform repository provisioning isolated AWS infrastructure across `dev`, `staging`, and `prod` environments. It features automated S3 + DynamoDB state locking, AWS Secrets Manager with KMS encryption, App Runner application services with ECR, VPC networking across multiple AZs, and keyless GitHub Actions CI/CD pipelines using AWS OIDC.

---

## 🏗️ ASCII Architecture Diagrams

### Dev Environment (`environments/dev`)
```
+-----------------------------------------------------------------------+
| Dev VPC (10.1.0.0/16) - 1 Availability Zone                           |
|                                                                       |
|  +-----------------------+           +-----------------------------+  |
|  | Public Subnet 1       |           | Private Subnet 1            |  |
|  | (10.1.1.0/24)         |           | (10.1.10.0/24)              |  |
|  |  [Internet Gateway]   |           |                             |  |
|  |  [NAT Gateway (1)] <--------------+-- [App Runner VPC Conn]     |  |
|  |                       |           |  [EC2 t3.micro (SSM)]       |  |
|  +-----------------------+           +-----------------------------+  |
+-----------------------------------------------------------------------+
```

### Staging Environment (`environments/staging`)
```
+-----------------------------------------------------------------------+
| Staging VPC (10.2.0.0/16) - 2 Availability Zones                      |
|                                                                       |
|  +-----------------------+           +-----------------------------+  |
|  | Public Subnet 1 & 2   |           | Private Subnet 1 & 2        |  |
|  | (10.2.1.0 / 10.2.2.0) |           | (10.2.10.0 / 10.2.20.0)     |  |
|  |  [Internet Gateway]   |           |                             |  |
|  |  [Shared NAT Gateway]<------------+-- [App Runner VPC Conn]     |  |
|  +-----------------------+           +-----------------------------+  |
+-----------------------------------------------------------------------+
```

### Production Environment (`environments/prod`)
```
+-----------------------------------------------------------------------+
| Production VPC (10.3.0.0/16) - 3 Availability Zones (HA)              |
|                                                                       |
|  +-----------------------+           +-----------------------------+  |
|  | Public Subnets (1-3)  |           | Private Subnets (1-3)       |  |
|  | (10.3.1.0-3.0/24)     |           | (10.3.10.0-30.0/24)         |  |
|  |  [Internet Gateway]   |           |                             |  |
|  |  [3x NAT Gateways] <--------------+-- [App Runner VPC Conn (HA)]|  |
|  |  (1 per AZ)           |           |  [Secrets KMS Auto-Rotate]  |  |
|  +-----------------------+           +-----------------------------+  |
+-----------------------------------------------------------------------+
```

---

## 📋 Prerequisites

Before deploying, ensure you have installed and configured:
1. **AWS CLI v2**: `aws --version`
2. **Terraform >= 1.5.0**: `terraform --version`
3. **AWS Credentials**: Configured with proper admin/provisioning IAM permissions.
4. **GitHub CLI (Optional)**: `gh --version` for managing repository secrets.

---

## ⚡ Quick Start

### Step 1: Bootstrap Remote State (S3 Bucket & DynamoDB Table)

Run the bootstrap script to create the S3 state bucket and DynamoDB locking table:

```bash
./scripts/bootstrap.sh us-east-1
```

### Step 2: Deploy Environment

Use the deployment helper script for your target environment (`dev`, `staging`, or `prod`):

```bash
# Deploy Dev Environment
./scripts/deploy.sh dev us-east-1

# Deploy Staging Environment
./scripts/deploy.sh staging us-east-1

# Deploy Production Environment
./scripts/deploy.sh prod us-east-1
```

### Step 3: Destroy Environment (If Needed)

To tear down resources safely:

```bash
./scripts/destroy.sh dev us-east-1
```

---

## 📦 Terraform Module Documentation

| Module Path | Created AWS Resources | Key Input Variables | Primary Outputs |
| :--- | :--- | :--- | :--- |
| [`modules/networking`](file:///c:/GitHub/terraform-aws-multienv/modules/networking) | VPC, Public/Private Subnets, IGW, NAT Gateways, Route Tables, SGs | `vpc_cidr`, `public_subnet_cidrs`, `private_subnet_cidrs`, `single_nat_gateway` | `vpc_id`, `public_subnet_ids`, `private_subnet_ids`, `security_group_ids` |
| [`modules/secretsmanager`](file:///c:/GitHub/terraform-aws-multienv/modules/secretsmanager) | Secrets Manager Secret, Version, KMS CMK Key, Key Alias, Rotation Policy | `secret_name`, `recovery_window_days`, `enable_rotation`, `rotation_days` | `secret_id`, `secret_arn`, `kms_key_arn` |
| [`modules/apprunner`](file:///c:/GitHub/terraform-aws-multienv/modules/apprunner) | App Runner Service, ECR Repo, IAM Access/Instance Roles, CloudWatch Logs, VPC Connector | `cpu`, `memory`, `min_size`, `max_size`, `image_uri`, `secret_arns`, `subnet_ids` | `app_runner_service_arn`, `app_runner_service_url`, `ecr_repository_url` |
| [`modules/compute`](file:///c:/GitHub/terraform-aws-multienv/modules/compute) | EC2 Instance, Security Group, EBS Volume, IAM Instance Profile for SSM | `instance_type`, `vpc_id`, `subnet_id`, `associate_public_ip`, `ebs_volume_size` | `instance_id`, `instance_private_ip`, `iam_instance_profile_arn` |

---

## 💰 Estimated Monthly AWS Cost per Environment

| Environment | Cost Component Breakdown | Estimated Monthly Total |
| :--- | :--- | :--- |
| **Dev** | - 1x NAT Gateway (~$32/mo) + Data Transfer<br>- 1x EC2 `t3.micro` (~$8.50/mo)<br>- 1x App Runner (0.25 vCPU / 0.5 GB) (~$5/mo)<br>- Secrets Manager & KMS (~$1.50/mo) | **~$47.00 / month** |
| **Staging** | - 1x NAT Gateway (~$32/mo) + Data Transfer<br>- App Runner (0.5 vCPU / 1 GB) (~$15/mo)<br>- Secrets Manager & KMS (~$1.50/mo) | **~$48.50 / month** |
| **Prod** | - 3x NAT Gateways HA (~$96/mo) + Data Transfer<br>- App Runner (1.0 vCPU / 2 GB, Min 2 instances) (~$60/mo)<br>- KMS Key + Secret Rotation (~$2.00/mo) | **~$158.00 / month** |

---

## 🚀 CI/CD Pipeline & OIDC Authentication

### GitHub Actions Workflows

1. **[`terraform-plan.yml`](file:///c:/GitHub/terraform-aws-multienv/.github/workflows/terraform-plan.yml)** (Triggered on Pull Request):
   - Uses `dorny/paths-filter` to detect which environment directory changed.
   - Runs `terraform fmt -check`, `terraform validate`, and `terraform plan`.
   - Posts formatted plan results as a comment directly on the Pull Request.

2. **[`terraform-apply.yml`](file:///c:/GitHub/terraform-aws-multienv/.github/workflows/terraform-apply.yml)** (Triggered on Push to `main` or Manual Trigger):
   - Runs `terraform apply -auto-approve`.
   - Production deployment is gated behind GitHub Environment protection rules requiring manual reviewer approval.

### Setting Up AWS OIDC for GitHub Actions (No Long-Lived Keys)

1. Create an AWS IAM OIDC Provider for GitHub:
   - Provider URL: `https://token.actions.githubusercontent.com`
   - Audience: `sts.amazonaws.com`

2. Create an IAM Role (e.g., `github-actions-terraform-role`) with Trust Policy:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Principal": {
           "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
         },
         "Action": "sts:AssumeRoleWithWebIdentity",
         "Condition": {
           "StringEquals": {
             "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
           },
           "StringLike": {
             "token.actions.githubusercontent.com:sub": "repo:YOUR_GITHUB_ORG/terraform-aws-multienv:*"
           }
         }
       }
     ]
   }
   ```

3. Set Repository Secrets in GitHub:
   ```bash
   gh secret set AWS_ROLE_ARN -b "arn:aws:iam::YOUR_ACCOUNT_ID:role/github-actions-terraform-role"
   gh secret set AWS_REGION -b "us-east-1"
   ```
