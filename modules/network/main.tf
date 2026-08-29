resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "vpc-data-${var.env}"
    Environment = var.env
  }
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnets_cidr)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnets_cidr[count.index]
  availability_zone = var.azs[count.index]

  tags = {
    Name        = "subnet-private-${var.env}-${count.index + 1}"
    Environment = var.env
  }
}

# Tabla de rutas para las subredes privadas (sin salida a internet)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name        = "rt-private-${var.env}"
    Environment = var.env
  }
}

# Asociación de la tabla de rutas con las subredes privadas
resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# Gateway Endpoint para S3
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.this.id
  service_name = "com.amazonaws.${var.region}.s3"
  
  vpc_endpoint_type = "Gateway"

  tags = {
    Name        = "vpce-s3-${var.env}"
    Environment = var.env
  }
}

# Asociación del Endpoint con la tabla de rutas privada
resource "aws_vpc_endpoint_route_table_association" "s3_private" {
  route_table_id  = aws_route_table.private.id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}
