# Bucket S3 para el Lakehouse (con versionado para Iceberg)
resource "aws_s3_bucket" "lakehouse_bucket" {
  bucket = "${var.env_name}-lakehouse-${var.account_id}"
}

resource "aws_s3_bucket_versioning" "lakehouse_versioning" {
  bucket = aws_s3_bucket.lakehouse_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Base de Datos en AWS Glue Data Catalog
resource "aws_glue_catalog_database" "lakehouse_db" {
  name        = "${var.env_name}_lakehouse_db"
  description = "Catalogo central para tablas Iceberg"
}