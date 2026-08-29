# DataOps Base Infrastructure - Checkpoint 1

Este repositorio contiene el andamiaje inicial para una plataforma de datos (Lakehouse/Streaming). Está modularizado separando recursos de Red (`network`) e Identidad (`identity`) siguiendo las mejores prácticas de DataOps.

## Pre-requisitos (Bootstrap del Backend)
Antes de ejecutar `terraform init`, necesitas un bucket S3 para el estado y una tabla de DynamoDB para el state locking. Puedes crearlos con AWS CLI:

```bash
# Crear Bucket S3 con cifrado
aws s3api create-bucket --bucket tu-bucket-terraform-state-dev --region us-east-1
aws s3api put-bucket-encryption --bucket tu-bucket-terraform-state-dev \
  --server-side-encryption-configuration '{"Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]}'

# Crear tabla DynamoDB
aws dynamodb create-table \
  --table-name terraform-state-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1





  ## Pre-entrega 2: Ingesta Real-Time (Capa Bronze)

### Prueba de Ingesta con AWS CLI
Para inyectar registros en el Kinesis Data Stream evitando Hot Shards, se utiliza una PartitionKey dinámica. Comando utilizado:

```bash
aws kinesis put-record \
  --stream-name dev-data-stream \
  --partition-key $(uuidgen) \
  --data $(echo '{"event_type": "test_ingesta", "value": 100}' | base64)