# Bucket S3 para guardar el código de Flink y los Checkpoints
resource "aws_s3_bucket" "flink_state" {
  bucket = "${var.env_name}-flink-state-${var.account_id}"
}

# Aplicación Managed Service for Apache Flink
resource "aws_kinesisanalyticsv2_application" "flink_processor" {
  name                   = "${var.env_name}-sensor-analytics"
  runtime_environment    = "FLINK-1_15"
  service_execution_role = aws_iam_role.flink_execution_role.arn

  application_configuration {
    application_code_configuration {
      code_content {
        s3_content_location {
          bucket_arn = aws_s3_bucket.flink_state.arn
          file_key   = "scripts/processor.zip"
        }
      }
      code_content_type = "ZIPFILE"
    }

    flink_application_configuration {
      # Configuración de Checkpoints exigida por el TP
      checkpoint_configuration {
        configuration_type = "CUSTOM"
        checkpointing_enabled = true
        checkpoint_interval = 60000
      }
      monitoring_configuration {
        configuration_type = "CUSTOM"
        log_level          = "INFO"
        metrics_level      = "APPLICATION"
      }
    }
  }
}

# Rol de seguridad para la ejecución de Flink
resource "aws_iam_role" "flink_execution_role" {
  name = "${var.env_name}-flink-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "kinesisanalytics.amazonaws.com"
        }
      }
    ]
  })
}