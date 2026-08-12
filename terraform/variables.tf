variable "aws_region" {
  default = "us-east-1"
}

variable "cluster_name" {
  default = "restauranty-cluster-nazmul"
}

variable "cluster_version" {
  default = "1.33"
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
}
