variable "cluster_name" {
  default = "ekscluster"
}

variable "private_subnets" {
  type = list(string)
}