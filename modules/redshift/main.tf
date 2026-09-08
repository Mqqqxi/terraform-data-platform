# Rol IAM para que Redshift pueda leer de Kinesis y acceder a Glue Data Catalog
resource "aws_iam_role" "redshift_execution_role" {
  name = "${var.env_name}-redshift-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "redshift.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "redshift_streaming_policy" {
  name = "${var.env_name}-redshift-streaming-policy"
  role = aws_iam_role.redshift_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kinesis:DescribeStream",
          "kinesis:GetRecords",
          "kinesis:GetShardIterator",
          "kinesis:ListShards",
          "kinesis:ListStreams"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "glue:GetDatabase",
          "glue:GetDatabases",
          "glue:GetTable",
          "glue:GetTables",
          "glue:GetPartition",
          "glue:GetPartitions"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = "*"
      }
    ]
  })
}

# Clúster de Redshift para Analítica In-stream
resource "aws_redshift_cluster" "analytics_cluster" {
  cluster_identifier     = "${var.env_name}-analytics-cluster"
  database_name          = "lakehousedb"
  master_username        = "adminuser"
  master_password        = "AdminPassword123!"
  node_type              = "dc2.large"
  cluster_type           = "single-node"
  iam_roles = [aws_iam_role.redshift_execution_role.arn]
  skip_final_snapshot    = true
}