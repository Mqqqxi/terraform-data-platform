-- =========================================================================
-- PRE-ENTREGA 6: ANALÍTICA AVANZADA IN-STREAM Y LAKEHOUSE CON REDSHIFT
-- =========================================================================

-- 1. CREACIÓN DEL EXTERNAL SCHEMA (Integración con Glue Data Catalog e Iceberg)
CREATE EXTERNAL SCHEMA IF NOT EXISTS glue_lakehouse_schema
FROM GLUE 
DATABASE 'dev_lakehouse_db'
IAM_ROLE 'arn:aws:iam::978841975519:role/dev-redshift-execution-role';


-- 2. REDSHIFT STREAMING INGESTION (Conexión directa Kinesis -> Redshift)
CREATE EXTERNAL TABLE kinesis_streaming_source (
    approximate_arrival_timestamp TIMESTAMP,
    partition_key VARCHAR(256),
    shard_id VARCHAR(128),
    payload VARCHAR(65535)
)
STORED AS TEXTFILE
LOCATION 'kinesis://dev-data-stream'
TABLE PROPERTIES (
    'num.shards'='2',
    'aws_iam_role'='arn:aws:iam::978841975519:role/dev-redshift-execution-role',
    'region'='us-east-1'
);


-- 3. MATERIALIZED VIEW DE TIEMPO REAL
-- Extrae y parsea campos genéricos del JSON (event_id, timestamp, value)
CREATE MATERIALIZED VIEW mv_events_realtime AS
SELECT 
    JSON_EXTRACT_PATH_TEXT(payload, 'event_id', TRUE)::VARCHAR(64) AS event_id,
    JSON_EXTRACT_PATH_TEXT(payload, 'payload_value', TRUE)::DOUBLE PRECISION AS event_value,
    CAST(JSON_EXTRACT_PATH_TEXT(payload, 'event_timestamp', TRUE) AS TIMESTAMP) AS event_time,
    approximate_arrival_timestamp AS ingestion_time
FROM kinesis_streaming_source;


-- 4. REFRESCAMIENTO INCREMENTAL DE LA VISTA MATERIALIZADA
REFRESH MATERIALIZED VIEW mv_events_realtime;


-- 5. CONSULTA HÍBRIDA (JOIN: Datos Calientes + Datos Históricos)
SELECT 
    rt.event_id,
    rt.event_value AS valor_actual,
    rt.event_time,
    hist.valor_historico_promedio,
    'Streaming + Lakehouse' AS fuente_datos
FROM mv_events_realtime rt
LEFT JOIN (
    -- Subconsulta sobre el almacenamiento histórico Iceberg en S3
    SELECT id AS event_id, AVG(valor) AS valor_historico_promedio
    FROM glue_lakehouse_schema.historical_events
    GROUP BY id
) hist ON rt.event_id = hist.event_id
WHERE rt.event_time >= SYSDATE - INTERVAL '1 HOUR';


-- 6. CAPA DE SEGURIDAD Y GOBERNANZA
CREATE ROLE analytics_viewer_role;
GRANT USAGE ON SCHEMA glue_lakehouse_schema TO ROLE analytics_viewer_role;
GRANT SELECT ON mv_events_realtime TO ROLE analytics_viewer_role;