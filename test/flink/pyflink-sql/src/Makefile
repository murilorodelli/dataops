
all: build push

build:
	DOCKER_BUILDKIT=1 docker build . -t images.k8s.local:5000/flink-sql:latest

push:
	docker push images.k8s.local:5000/flink-sql:latest