terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    # Key is specified per environment; bucket, region, and dynamodb_table
    # are passed via partial backend configuration at `terraform init`.
    key     = "dev/terraform.tfstate"
    encrypt = true
  }
}
