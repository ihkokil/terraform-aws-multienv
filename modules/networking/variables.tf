variable "environment" {
  description = "Target deployment environment (dev, staging, prod)"
  type        = string
}

variable "region" {
  description = "AWS region for network deployment"
  type        = string
}

variable "project_name" {
  description = "Project name prefix for resource naming convention"
  type        = string
  default     = "myapp"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)
}

variable "availability_zones" {
  description = "List of availability zones to distribute subnets across"
  type        = list(string)
}

variable "single_nat_gateway" {
  description = "If true, provision a single shared NAT Gateway across all private subnets. If false, provision one NAT Gateway per AZ."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags applied to all networking resources"
  type        = map(string)
  default     = {}
}
