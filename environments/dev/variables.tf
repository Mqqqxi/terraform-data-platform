variable "region" {
  type    = string
  default = "us-east-2"
}

variable "env" {
  type    = string
  default = "dev"
}

variable "vpc_cidr" {
  type    = string
}

variable "private_subnets_cidr" {
  type    = list(string)
}

variable "azs" {
  type    = list(string)
}