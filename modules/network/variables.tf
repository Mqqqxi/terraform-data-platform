variable "env" {
  description = "Nombre del entorno (ej. dev, prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block para la VPC"
  type        = string
}

variable "private_subnets_cidr" {
  description = "Lista de CIDRs para las subredes privadas"
  type        = list(string)
}

variable "azs" {
  description = "Zonas de disponibilidad a utilizar"
  type        = list(string)
}

variable "region" {
  description = "Región de AWS"
  type        = string
}