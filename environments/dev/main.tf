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
  
  # Reemplazá esto por el ARN real de tu bucket creado en el TP1. 
  # Si lo creaste con otro módulo, podés pasarlo como variable (ej: module.storage.bucket_arn)
  s3_bucket_arn = "arn:aws:s3:::maxi-terraform-state-dev-123" 
}

