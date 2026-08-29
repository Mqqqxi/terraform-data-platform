module "network" {
  source = "../../modules/network"

  env                  = var.env
  region               = var.region
  vpc_cidr             = var.vpc_cidr
  private_subnets_cidr = var.private_subnets_cidr
  azs                  = var.azs
}

module "identity" {
  source = "../../modules/identity"

  env                = var.env
  # Estos valores pueden venir de variables, los definimos estáticos para el TP
  target_bucket_name = "mi-futuro-lakehouse-bucket" 
  target_prefix      = "streaming-data/"
}