variable "environment" {
  description = "Target environment name (dev, staging, prod)"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "project_name" {
  description = "Project name prefix"
  type        = string
  default     = "myapp"
}

variable "service_name" {
  description = "App Runner service name suffix"
  type        = string
  default     = "web"
}

variable "cpu" {
  description = "Number of vCPU units (0.25 vCPU = 256, 0.5 vCPU = 512, 1 vCPU = 1024, 2 vCPU = 2048)"
  type        = string
  default     = "256"
}

variable "memory" {
  description = "Amount of memory in MB (0.5 GB = 512, 1 GB = 1024, 2 GB = 2048, 3 GB = 3072, 4 GB = 4096)"
  type        = string
  default     = "512"
}

variable "min_size" {
  description = "Minimum number of concurrent instances for auto scaling"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of concurrent instances for auto scaling"
  type        = number
  default     = 3
}

variable "image_uri" {
  description = "Docker image URI (ECR or public container image). Defaults to public sample image."
  type        = string
  default     = "public.ecr.aws/aws-containers/hello-app-runner:latest"
}

variable "env_vars" {
  description = "Environment variables key-value map for App Runner application runtime"
  type        = map(string)
  default     = {}
}

variable "secret_arns" {
  description = "List of Secrets Manager ARNs to grant App Runner IAM role access to"
  type        = list(string)
  default     = []
}

variable "subnet_ids" {
  description = "List of private subnet IDs for the App Runner VPC connector"
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  description = "List of security group IDs for the App Runner VPC connector"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to attach to App Runner resources"
  type        = map(string)
  default     = {}
}
