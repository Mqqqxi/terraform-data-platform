import boto3
import json
import uuid
import time
from datetime import datetime

# Configura el nombre de tu stream
STREAM_NAME = 'dev-data-stream' 
kinesis_client = boto3.client('kinesis', region_name='us-east-2')

def generate_event():
    return {
        "event_id": str(uuid.uuid4()),
        "timestamp": datetime.utcnow().isoformat(),
        "event_type": "user_click",
        "value": 42
    }

print(f"Iniciando ingesta de 100 registros en {STREAM_NAME}...")

for i in range(100):
    event_data = generate_event()
    
    # PartitionKey dinámica evita Hot Shards
    partition_key = str(uuid.uuid4()) 
    
    response = kinesis_client.put_record(
        StreamName=STREAM_NAME,
        Data=json.dumps(event_data),
        PartitionKey=partition_key
    )
    
    print(f"Registro {i+1}/100 enviado - ShardId: {response['ShardId']}")
    time.sleep(0.1) # Pequeña pausa para no saturar la terminal

print("Ingesta finalizada.")