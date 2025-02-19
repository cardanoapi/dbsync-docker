# Step 1: Build Stage using musl to create a statically linked executable
FROM alpine:latest AS json_update

# Install necessary build dependencies, including autoconf and libtool
RUN apk add --no-cache \
    gcc \
    musl-dev \
    make \
    wget \
    libc-dev \
    zlib-dev \
    git \
    autoconf \
    automake \
    libtool

# Install jansson from source
RUN git clone https://github.com/akheron/jansson.git /jansson && \
    cd /jansson && \
    autoreconf -i && \
    ./configure && \
    make && \
    make install && \
    cd .. && \
    rm -rf /jansson

# Set the working directory inside the container
WORKDIR /app

# Copy the C program into the container
COPY ./json_merge/update_json.c .

# Compile the C program statically using musl-gcc
RUN gcc -o update_json update_json.c -ljansson -static



FROM ubuntu:24.04 AS config
RUN apt-get update && apt-get install -y git \
    && git clone --depth 1 --filter=blob:none --sparse --no-checkout https://github.com/input-output-hk/cardano-playground.git \
    && cd cardano-playground \
    && git sparse-checkout set docs/environments \
    && git checkout

ARG DBSYNC_TAG=13.6.0.4

FROM ghcr.io/intersectmbo/cardano-db-sync:${DBSYNC_TAG:-13.6.0.4}
COPY --from=json_update /app/update_json /bin/update_json
COPY --from=config /cardano-playground/docs/environments /environments
COPY ./entrypoint.sh /
ENTRYPOINT ["/bin/bash", "-e", "/entrypoint.sh" ]