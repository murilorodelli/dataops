import json
import logging

from pyflink.common.serialization import SimpleStringSchema
from pyflink.common.typeinfo import Types
from pyflink.common.watermark_strategy import WatermarkStrategy
from pyflink.datastream import StreamExecutionEnvironment
from pyflink.datastream.connectors.kafka import KafkaRecordSerializationSchema, KafkaSink, KafkaSource


def main() -> None:
    # Set up logging to display info and error messages
    logging.basicConfig(level=logging.INFO)

    # Set up the streaming execution environment
    env = StreamExecutionEnvironment.get_execution_environment()
    env.add_jars("file:///opt/flink/lib/flink-sql-connector-kafka-3.2.0-1.18.jar")

    # Enable checkpointing every 5000 milliseconds (optional but recommended)
    env.enable_checkpointing(5000)

    # Create the Kafka source to consume messages from 'test-input' topic
    kafka_source = (
        KafkaSource.builder()
        .set_bootstrap_servers("integrationhub-kafka-bootstrap.kafka.svc.cluster.local:9092")
        .set_topics("test-input")
        .set_group_id("testGroup")
        .set_value_only_deserializer(SimpleStringSchema())
        .build()
    )

    # Create a data stream from the Kafka source
    data_stream = env.from_source(
        source=kafka_source,
        watermark_strategy=WatermarkStrategy.no_watermarks(),  # No watermarks for simplicity
        source_name="Kafka Source",
    )

    # Define a processing function to parse JSON messages
    def process_json(value: str) -> str:
        """
        Process each JSON message.
        """
        logging.info("Received message: %s", value)
        try:
            # Parse the JSON string into a Python dictionary
            data = json.loads(value)
            logging.info("Parsed JSON: %s", data)
            # Additional processing can be added here
            return json.dumps(data)  # Convert back to JSON string
        except json.JSONDecodeError as e:
            logging.error("Failed to parse JSON: %s - %s", value, e)
            return None  # Return None if parsing fails

    # Apply the processing function and filter out any None values
    processed_stream = data_stream.map(process_json, output_type=Types.STRING()).filter(lambda x: x is not None)

    # Create the Kafka sink to produce messages to 'test-output' topic
    kafka_sink = (
        KafkaSink.builder()
        .set_bootstrap_servers("integrationhub-kafka-bootstrap.kafka.svc.cluster.local:9092")
        .set_record_serializer(
            KafkaRecordSerializationSchema.builder()
            .set_topic("test-output")  # Specify the target topic
            .set_value_serialization_schema(SimpleStringSchema())
            .build()
        )
        .build()
    )

    # Add the sink to the data stream
    processed_stream.sink_to(kafka_sink)

    # Execute the Flink job with a descriptive name
    env.execute("Kafka JSON Processing Job")


if __name__ == "__main__":
    main()
