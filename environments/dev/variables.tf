variable "region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name identifier"
  type        = string
  default     = "myapp"
}

variable "vpc_cidr" {
  description = "CIDR block for dev VPC"
  type        = string
  default     = "10.1.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for dev public subnets"
  type        = list(string)
  default     = ["10.1.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for dev private subnets"
  type        = list(string)
  default     = ["10.1.10.0/24"]
}

variable "app_runner_cpu" {
  description = "App Runner CPU setting (256 = 0.25 vCPU)"
  type        = string
  default     = "256"
}

variable "app_runner_memory" {
  description = "App Runner Memory setting (512 = 0.5 GB)"
  type        = string
  default     = "512"
}

variable "secret_recovery_window_days" {
  description = "Recovery window for Secrets Manager deletion in dev"
  type        = number
  default     = 0
}

variable "ec2_instance_type" {
  description = "EC2 Instance type for dev environment"
  type        = string
  default     = "t3.micro"
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
