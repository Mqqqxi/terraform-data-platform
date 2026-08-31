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

module "ingestion" {
  source = "../../modules/kinesis" # La ruta relativa hacia tu nuevo módulo

  env_name      = "dev"
  

  s3_bucket_arn = "arn:aws:s3:::maxi-terraform-state-dev-123" 
}

# Módulo de Procesamiento Real-Time con Flink
module "processing" {
  source = "../../modules/processing"

  env_name   = "dev"
  account_id = "978841975519"
}


module "lakehouse" {
  source     = "../../modules/lakehouse"
  env_name   = "dev"
  account_id = "978841975519"
}