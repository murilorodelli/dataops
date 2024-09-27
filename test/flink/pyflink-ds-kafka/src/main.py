import logging
import sys

from pyflink.common import Types
from pyflink.datastream import StreamExecutionEnvironment
from pyflink.datastream.connectors.kafka import FlinkKafkaConsumer, FlinkKafkaProducer
from pyflink.datastream.formats.json import JsonRowDeserializationSchema, JsonRowSerializationSchema


def write_to_kafka(env: StreamExecutionEnvironment) -> None:
    type_info = Types.ROW([Types.INT(), Types.STRING()])
    ds = env.from_collection(
        [
            (1, "hi"),
            (2, "hello"),
            (3, "hi"),
            (4, "hello"),
            (5, "hi"),
            (6, "hello"),
            (6, "hello"),
        ],
        type_info=type_info,
    )

    serialization_schema = JsonRowSerializationSchema.Builder().with_type_info(type_info).build()
    kafka_producer = FlinkKafkaProducer(
        topic="test-input",
        serialization_schema=serialization_schema,
        producer_config={
            "bootstrap.servers": "integrationhub-kafka-bootstrap.kafka.svc.cluster.local:9092",
            "group.id": "test_group",
        },
    )

    # note that the output type of ds must be RowTypeInfo
    ds.add_sink(kafka_producer)
    env.execute()


# def read_from_kafka(env: StreamExecutionEnvironment) -> None:
#     deserialization_schema = (
#         JsonRowDeserializationSchema.Builder().type_info(Types.ROW([Types.INT(), Types.STRING()])).build()
#     )
#     kafka_consumer = FlinkKafkaConsumer(
#         topics="test-output",
#         deserialization_schema=deserialization_schema,
#         properties={
#             "bootstrap.servers": "integrationhub-kafka-bootstrap.kafka.svc.cluster.local:9092",
#             "group.id": "test_group_1",
#         },
#     )
#     kafka_consumer.set_start_from_earliest()

#     env.add_source(kafka_consumer).print()
#     env.execute()


if __name__ == "__main__":
    logging.basicConfig(stream=sys.stdout, level=logging.INFO, format="%(message)s")

    env = StreamExecutionEnvironment.get_execution_environment()
    env.add_jars("file:///opt/flink/lib/flink-sql-connector-kafka-3.2.0-1.18.jar")

    print("start writing data to kafka")
    write_to_kafka(env)

    # print("start reading data from kafka")
    # read_from_kafka(env)
