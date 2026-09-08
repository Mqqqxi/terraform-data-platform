# modules/kinesis/main.tf

variable "env_name" {
  description = "Nombre del entorno para los tags (ej: dev, prod)"
  type        = string
}

variable "s3_bucket_arn" {
  description = "ARN del bucket S3 del Data Lake"
  type        = string
}

# 1. Kinesis Data Stream
resource "aws_kinesis_stream" "this" {
  name             = "${var.env_name}-data-stream"
  shard_count      = 2
  retention_period = 24
  encryption_type  = "KMS"
  kms_key_id       = "alias/aws/kinesis" 

  # ELIMINAMOS EL BLOQUE "tags" PARA EVITAR EL ERROR DE SCP
}

# 2. IAM Role para Kinesis Firehose
resource "aws_iam_role" "firehose_role" {
  name = "${var.env_name}-firehose-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "firehose.amazonaws.com"
        }
      }
    ]
  })
}

# 3. Políticas de IAM (Lectura de Kinesis, Escritura en S3 y Logs)
resource "aws_iam_role_policy" "firehose_policy" {
  name = "${var.env_name}-firehose-policy"
  role = aws_iam_role.firehose_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kinesis:DescribeStream",
          "kinesis:GetShardIterator",
          "kinesis:GetRecords",
          "kinesis:ListShards"
        ]
        Resource = aws_kinesis_stream.this.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject"
        ]
        Resource = [
          var.s3_bucket_arn,
          "${var.s3_bucket_arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:PutLogEvents"
        ]
        Resource = [
          "arn:aws:logs:*:*:log-group:/aws/kinesisfirehose/*:log-stream:*"
        ]
      }
    ]
  })
}

# 4. Kinesis Data Firehose
resource "aws_kinesis_firehose_delivery_stream" "this" {
  name        = "${var.env_name}-firehose-delivery"
  destination = "extended_s3"

  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.this.arn
    role_arn           = aws_iam_role.firehose_role.arn
  }

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose_role.arn
    bucket_arn = var.s3_bucket_arn

    # Política agresiva para desarrollo
    buffering_size     = 5
    buffering_interval = 60

    prefix              = "ingesta/year=!{timestamp:yyyy}/"
    error_output_prefix = "errores/year=!{timestamp:yyyy}/!{firehose:error-output-type}/"
  }
}