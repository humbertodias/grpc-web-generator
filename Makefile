TAG:=hldtux/grpc-web-generator
build:
	docker build . -t $(TAG)
push:
	docker push $(TAG)