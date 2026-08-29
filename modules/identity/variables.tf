variable "env" {
  description = "Entorno (ej. dev)"
  type        = string
}

variable "target_bucket_name" {
  description = "Nombre del bucket S3 del Data Lakehouse"
  type        = string
}

variable "target_prefix" {
  description = "Prefijo específico dentro del bucket (ej. raw/streaming/)"
  type        = string
}