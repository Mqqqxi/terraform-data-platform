# 1. Rol de Procesamiento de Datos (Lambda/Flink)
data "aws_iam_policy_document" "data_processing_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      # Asumiendo el uso futuro de Lambda o Kinesis Analytics (Flink)
      identifiers = ["lambda.amazonaws.com", "kinesisanalytics.amazonaws.com"] 
    }
  }
}

resource "aws_iam_role" "data_processing" {
  name               = "role-data-processing-${var.env}"
  assume_role_policy = data.aws_iam_policy_document.data_processing_assume.json
}

data "aws_iam_policy_document" "data_processing_s3" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::${var.target_bucket_name}"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::${var.target_bucket_name}/${var.target_prefix}*"
    ]
  }
}

resource "aws_iam_policy" "data_processing_s3" {
  name        = "policy-s3-data-processing-${var.env}"
  description = "Permite acceso de lectura/escritura a un prefijo especifico en S3"
  policy      = data.aws_iam_policy_document.data_processing_s3.json
}

resource "aws_iam_role_policy_attachment" "data_processing_s3_attach" {
  role       = aws_iam_role.data_processing.name
  policy_arn = aws_iam_policy.data_processing_s3.arn
}

# 2. Rol del Plano de Control para Auditoría
data "aws_iam_policy_document" "audit_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      # Reemplazar con el Account ID o rol de los administradores
      identifiers = ["arn:aws:iam::978841975519:root"] 
    }
  }
}

resource "aws_iam_role" "audit_control_plane" {
  name               = "role-audit-control-plane-${var.env}"
  assume_role_policy = data.aws_iam_policy_document.audit_assume.json
}

# Usamos la política administrada de AWS para ReadOnly
resource "aws_iam_role_policy_attachment" "audit_readonly" {
  role       = aws_iam_role.audit_control_plane.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}