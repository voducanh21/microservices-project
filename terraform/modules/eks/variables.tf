variable "cluster_name" {}
variable "cluster_version" {}
variable "subnet_ids" {
  type = list(string)
}
variable "vpc_id" {}
variable "principal_arn" {}
variable "policy_arn" {}
variable "tags" {
  type = map(string)
}
