variable "environment" {
  description = "Target deployment environment (dev, staging, prod)"
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

variable "vpc_id" {
  description = "VPC ID where EC2 instance and security group will be created"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where the EC2 instance will be launched"
  type        = string
}

variable "instance_type" {
  description = "EC2 Instance Type"
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "Optional AMI ID override. If null, fetches latest Amazon Linux 2023 AMI."
  type        = string
  default     = null
}

variable "key_name" {
  description = "Optional SSH key pair name"
  type        = string
  default     = null
}

variable "associate_public_ip" {
  description = "Whether to associate a public IP address with the EC2 instance"
  type        = bool
  default     = false
}

variable "ebs_volume_size" {
  description = "Size of additional EBS Volume in GB"
  type        = number
  default     = 20
}

variable "tags" {
  description = "Common tags applied to compute resources"
  type        = map(string)
  default     = {}
}
