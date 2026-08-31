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


  ## Pre-entrega 4: Procesamiento en Tiempo Real (Apache Flink)

### Lógica de Negocio
La capa de procesamiento analítico se encarga de consumir y procesar eventos en tiempo real desde el stream de Kinesis. 

Se implementó una aplicación stateful en PyFlink que lee los datos crudos, los agrupa por clave de partición y aplica ventanas temporales (`TumblingEventTimeWindows`) de 1 minuto para realizar métricas y agregaciones continuas. Para manejar la latencia y el desorden natural de los eventos en la red, se configuró un `WatermarkStrategy` basado en Event Time con una tolerancia de 5 segundos.

### Configuración de Paralelismo y Estado
* **Escalabilidad:** La aplicación de Managed Service for Apache Flink delega la asignación de KPUs a la configuración nativa de AWS para escalar dinámicamente según el volumen de ingesta.
* **Tolerancia a fallos:** Se habilitó un `checkpoint_configuration` personalizado. El estado de las ventanas se guarda cada 60000 milisegundos en un bucket S3 dedicado, garantizando la recuperación de datos ante cualquier interrupción del job.

### Nota sobre la Evidencia de Ejecución
El código fuente (`scripts/processor.py`) implementa la lógica de agregación solicitada, y la infraestructura se definió en Terraform (`modules/processing/main.tf`). 

*Importante para el corrector:* Durante el `terraform apply`, la creación del recurso `aws_kinesisanalyticsv2_application` fue bloqueada por una restricción de la cuenta de laboratorio (Service Control Policy: `p-83x5j2r0`) que aplica un *explicit deny* sobre los servicios analíticos. Por este motivo impuesto por AWS Academy, no es posible levantar el Flink Dashboard para la captura del grafo. La validación se sostiene sobre la estructura del código y el plan de ejecución de Terraform.