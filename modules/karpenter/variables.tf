variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_endpoint" {
  description = "EKS cluster endpoint"
  type        = string
}

variable "oidc_provider_arn" {
  description = "EKS OIDC provider ARN"
  type        = string
}

variable "karpenter_version" {
  description = "Karpenter version"
  type        = string
  default     = "v0.32.1"
}

variable "karpenter_controller_iam_arn" {
  description = "Karpenter controller IAM role ARN"
  type        = string
}

variable "node_instance_profile" {
  description = "Karpenter node instance profile name"
  type        = string
}

variable "node_count" {
  description = "Number of initial nodes to create"
  type        = number
  default     = 4
}