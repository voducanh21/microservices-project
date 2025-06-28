variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-southeast-1"
}

variable "profile" {
  description = "AWS CLI named profile to use"
  type        = string
  default     = "default"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "microservices-cluster"
}
