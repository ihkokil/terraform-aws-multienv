# AWS Multi-Environment Infrastructure Architecture

This repository provisions a production-ready, highly available, secure, and multi-environment AWS infrastructure using Terraform modules.

## Architecture Overview

```
                      +-------------------------------------------------------+
                      |                 AWS Account (us-east-1)               |
                      |                                                       |
                      |   +-----------------------------------------------+   |
                      |   | Remote State: S3 (tfstate-<account>-<region>)  |   |
                      |   | State Lock:   DynamoDB (terraform-state-lock)  |   |
                      |   +-----------------------------------------------+   |
                      |                                                       |
                      +---------------------------+---------------------------+
                                                  |
           +--------------------------------------+--------------------------------------+
           |                                      |                                      |
           v                                      v                                      v
+-----------------------+              +-----------------------+              +-----------------------+
|    DEV ENVIRONMENT    |              |  STAGING ENVIRONMENT  |              |   PROD ENVIRONMENT    |
|                       |              |                       |              |                       |
|  - VPC (10.1.0.0/16)  |              |  - VPC (10.2.0.0/16)  |              |  - VPC (10.3.0.0/16)  |
|  - 1 AZ (Single)      |              |  - 2 AZs (Dual)       |              |  - 3 AZs (Multi-AZ)   |
|  - Single NAT Gateway |              |  - Single NAT Gateway |              |  - HA NAT Gateways    |
|  - EC2 (t3.micro) SSM |              |  - No EC2             |              |    (1 per AZ)         |
|  - App Runner (0.25v) |              |  - App Runner (0.5v)  |              |  - No EC2             |
|  - Secrets (0-day)    |              |  - Secrets (7-day)    |              |  - App Runner (1.0v)  |
|                       |              |                       |              |  - Secrets (30-day +  |
|                       |              |                       |              |    KMS Rotation)      |
+-----------------------+              +-----------------------+              +-----------------------+
```

## Environment Specifications Matrix

| Component | Dev (`environments/dev`) | Staging (`environments/staging`) | Prod (`environments/prod`) |
| :--- | :--- | :--- | :--- |
| **VPC CIDR** | `10.1.0.0/16` | `10.2.0.0/16` | `10.3.0.0/16` |
| **Availability Zones** | 1 | 2 | 3 |
| **NAT Gateway Strategy** | Single NAT Gateway | Single NAT Gateway | 1 NAT Gateway per AZ (High Availability) |
| **EC2 Bastion / Compute** | Enabled (`t3.micro`, SSM Session Manager) | None | None |
| **App Runner vCPU** | 0.25 vCPU (256) | 0.5 vCPU (512) | 1.0 vCPU (1024) |
| **App Runner Memory** | 0.5 GB (512 MB) | 1.0 GB (1024 MB) | 2.0 GB (2048 MB) |
| **App Runner Scaling** | Min: 1, Max: 2 | Min: 1, Max: 5 | Min: 2, Max: 10 |
| **Secrets Manager Window** | 0 Days | 7 Days | 30 Days |
| **Secret KMS Key** | Customer Master Key (CMK) | Customer Master Key (CMK) | CMK + Automated 30-day Rotation |
| **State Dependencies** | Independent | Independent | Reads Staging Outputs via Remote State |

## Security & Compliance Architecture

1. **Keyless SSM Session Manager**:
   - Zero open inbound SSH ports (port 22 closed everywhere).
   - Compute instances attach `AmazonSSMManagedInstanceCore` policy for secure AWS Systems Manager access.

2. **IAM & OIDC Identity Federation**:
   - GitHub Actions authenticates directly to AWS STS using OpenID Connect (OIDC).
   - Eliminates stored AWS static secret keys in GitHub settings.

3. **Secrets Manager Integration**:
   - App Runner tasks fetch secrets directly from AWS Secrets Manager using IAM service roles.
   - All secret values are encrypted at rest using customer-managed AWS KMS keys.

4. **Network Isolation & Egress Control**:
   - App Runner tasks run inside VPC private subnets using AWS App Runner VPC Connectors.
   - Private subnets route egress traffic through NAT Gateways.
