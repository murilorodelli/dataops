
all: build push

build:
	DOCKER_BUILDKIT=1 docker build . -t images.k8s.local:5000/pyflink-stream:mk1

push:
	docker push images.k8s.local:5000/pyflink-stream:mk1