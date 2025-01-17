FROM ubuntu:21.04 AS builder

ARG MAKEFLAGS=-j8
ARG GRPC_WEB_TAG=tags/1.2.1

RUN apt update && apt install -y \
  automake \
  build-essential \
  git \
  libtool \
  make

RUN git clone https://github.com/grpc/grpc-web /github/grpc-web

WORKDIR /github/grpc-web

RUN git checkout ${GRPC_WEB_TAG}

## Install gRPC and protobuf

RUN ./scripts/init_submodules.sh

RUN cd third_party/grpc && make && make install

RUN cd third_party/grpc/third_party/protobuf && make install

## Install all the gRPC-web plugin

RUN make install-plugin

FROM ubuntu:21.04

COPY --from=builder /usr/local/bin /usr/local/bin
COPY --from=builder /usr/local/include /usr/local/include

## Create the gRPC client
ENV import_style=commonjs
ENV grpc_web_import_style=commonjs
ENV mode=grpcwebtext
VOLUME /protofile
ENV protofile=echo.proto
ENV output=/protofile/generated

USER ubuntu

CMD protoc \
  -I=/protofile \
  /protofile/$protofile \
  --js_out=import_style=$import_style:$output \
  --grpc-web_out=import_style=$grpc_web_import_style,mode=$mode:$output