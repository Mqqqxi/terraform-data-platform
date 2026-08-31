import json

try:
    from pyflink.common import Types, WatermarkStrategy, Duration  # type: ignore[import-not-found]
    from pyflink.datastream import StreamExecutionEnvironment  # type: ignore[import-not-found]
    from pyflink.datastream.connectors.kinesis import FlinkKinesisConsumer  # type: ignore[import-not-found]
    from pyflink.datastream.window import TumblingEventTimeWindows  # type: ignore[import-not-found]
    from pyflink.datastream.functions import WindowFunction  # type: ignore[import-not-found]
except ImportError:
    # PyFlink is available only in the Flink runtime environment; this fallback prevents
    # IDE/static analysis errors when the dependency is not installed locally.
    Types = WatermarkStrategy = Duration = None  # type: ignore[assignment]
    StreamExecutionEnvironment = None  # type: ignore[assignment]
    FlinkKinesisConsumer = None  # type: ignore[assignment]
    TumblingEventTimeWindows = None  # type: ignore[assignment]

    class WindowFunction:  # type: ignore[no-redef]
        pass

# Definimos la función para procesar la ventana de tiempo
class AggregateSensorData(WindowFunction):
    def apply(self, key, window, inputs):
        # key: el identificador RFID
        # inputs: todos los eventos recibidos en esta ventana de 60 segundos
        total_peso = 0
        conteo = 0
        for event in inputs:
            # Extraemos la lectura del sensor de carga
            total_peso += event.get("sensor_de_carga", 0)
            conteo += 1
        
        promedio = total_peso / conteo if conteo > 0 else 0
        
        return [(
            key, 
            window.start, 
            window.end, 
            promedio, 
            conteo
        )]

def main():
    # 1. Configuración del Entorno y Checkpoints
    env = StreamExecutionEnvironment.get_execution_environment()
    env.enable_checkpointing(60000) # Checkpoint cada 1 minuto (Tolerancia a fallos)
    
    # 2. Configuración del Origen de Datos (Kinesis)
    consumer_config = {
        'aws.region': 'us-east-1',
        'flink.stream.initpos': 'LATEST'
    }
    
    # Asumimos que los datos entran como strings JSON
    kinesis_source = FlinkKinesisConsumer(
        stream="dev-data-stream",
        deserialization_schema=Types.STRING(),
        config=consumer_config
    )

    # 3. Ingesta y Deserialización
    stream = env.add_source(kinesis_source) \
                .map(lambda x: json.loads(x), output_type=Types.MAP(Types.STRING(), Types.FLOAT()))

    # 4. Estrategia de Watermarks (Event Time)
    # Tolerancia de 5 segundos para eventos tardíos en la red
    watermark_strategy = WatermarkStrategy.for_bounded_out_of_orderness(Duration.of_seconds(5)) \
        .with_timestamp_assigner(lambda event: int(event.get("timestamp", 0)))
    
    stream_with_watermarks = stream.assign_timestamps_and_watermarks(watermark_strategy)

    # 5. Lógica Stateful y Ventanas Temporales
    processed_stream = stream_with_watermarks \
        .key_by(lambda x: x.get("rfid", "desconocido")) \
        .window(TumblingEventTimeWindows.of(Duration.of_minutes(1))) \
        .apply(AggregateSensorData(), output_type=Types.TUPLE([Types.STRING(), Types.LONG(), Types.LONG(), Types.FLOAT(), Types.INT()]))

    # 6. Salida (En este caso, lo enviamos a los logs de CloudWatch para la validación)
    processed_stream.print()

    # Ejecución del Job
    env.execute("Procesamiento Analítico de Sensores de Carga y RFID")

if __name__ == '__main__':
    main()