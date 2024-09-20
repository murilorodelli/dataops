import ssl
import os

from kafka import KafkaProducer

context = ssl.create_default_context()
# ca.cert is in current directory
cert_file = os.path.join(os.path.dirname(__file__), "ca.crt")
context.load_verify_locations(cert_file)
context.check_hostname = False

producer = KafkaProducer(
    bootstrap_servers=["integrationhub-kafka-bootstrap.k8s.local:443"],
    # bootstrap_servers=["integrationhub-kafka-bootstrap.k8s.local:9094"],
    security_protocol="SSL",
    ssl_context=context,
)

producer.send("my-topic", b"Hello, Kafka!")
producer.flush()
producer.close()
