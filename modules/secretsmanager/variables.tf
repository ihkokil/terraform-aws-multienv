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

variable "secret_name" {
  description = "Custom secret name suffix or identifier"
  type        = string
  default     = "app-secrets"
}

variable "recovery_window_days" {
  description = "Number of days AWS Secrets Manager waits before deleting secret (0 to 30)"
  type        = number
  default     = 30
}

variable "enable_rotation" {
  description = "Whether to enable automatic secret rotation"
  type        = bool
  default     = false
}

variable "rotation_days" {
  description = "Automatically rotate secret every N days"
  type        = number
  default     = 30
}

variable "kms_key_id" {
  description = "Optional existing KMS Key ID or ARN. If null, a new customer master key (CMK) will be created."
  type        = string
  default     = null
}

variable "secret_string" {
  description = "Initial secret string payload (JSON string key/value map)"
  type        = string
  default     = "{\"username\":\"db_admin\",\"password\":\"ChangeMeInProduction123!\"}"
  sensitive   = true
}

variable "tags" {
  description = "Tags to attach to Secrets Manager resources"
  type        = map(string)
  default     = {}
}
