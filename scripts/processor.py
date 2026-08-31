import os
from pyflink.datastream import StreamExecutionEnvironment
from pyflink.table import StreamTableEnvironment, EnvironmentSettings

def main():
    # 1. Configuración del Entorno y Checkpoints (Fundamental para Iceberg)
    env = StreamExecutionEnvironment.get_execution_environment()
    env.enable_checkpointing(60000) # Checkpoints cada 1 min para el commit de metadatos
    
    settings = EnvironmentSettings.new_instance().in_streaming_mode().build()
    t_env = StreamTableEnvironment.create(env, environment_settings=settings)

    # 2. Configuración del Catálogo de Glue e Iceberg
    catalog_name = "my_glue_catalog"
    database_name = "dev_lakehouse_db"
    
    # Se crea el catálogo usando la implementación de Glue
    t_env.execute_sql(f"""
        CREATE CATALOG {catalog_name} WITH (
            'type'='iceberg',
            'catalog-impl'='org.apache.iceberg.aws.glue.GlueCatalog',
            'io-impl'='org.apache.iceberg.aws.s3.S3FileIO',
            'warehouse'='s3a://dev-lakehouse-978841975519/warehouse'
        )
    """)
    t_env.use_catalog(catalog_name)
    t_env.use_database(database_name)

    # 3. Creación de la tabla Iceberg apuntando al catálogo
    t_env.execute_sql("""
        CREATE TABLE IF NOT EXISTS mediciones_sensores (
            rfid STRING,
            sensor_de_carga DOUBLE,
            fecha DATE,
            event_time TIMESTAMP(3),
            WATERMARK FOR event_time AS event_time - INTERVAL '5' SECOND
        ) PARTITIONED BY (fecha, rfid)
    """)

    # 4. Ingesta desde Kinesis y Sink a Iceberg
    # (Aquí definimos la conexión a kinesis mediante SQL para facilitar el insert)
    t_env.execute_sql("""
        CREATE TABLE kinesis_source (
            rfid STRING,
            sensor_de_carga DOUBLE,
            event_time TIMESTAMP(3)
        ) WITH (
            'connector' = 'kinesis',
            'stream' = 'dev-data-stream',
            'aws.region' = 'us-east-1',
            'scan.stream.initpos' = 'LATEST',
            'format' = 'json'
        )
    """)

    # Inserción en tiempo real hacia Iceberg
    t_env.execute_sql("""
        INSERT INTO mediciones_sensores
        SELECT 
            rfid, 
            sensor_de_carga, 
            CAST(event_time AS DATE) as fecha, 
            event_time 
        FROM kinesis_source
    """)

if __name__ == '__main__':
    main()