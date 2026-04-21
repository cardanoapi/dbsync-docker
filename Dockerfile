ARG DBSYNC_TAG

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

# Step 2: Config Stage to fetch environment files
FROM ubuntu:24.04 AS config
RUN apt-get update && apt-get install -y git \
    && git clone --depth 1 --filter=blob:none --sparse --no-checkout https://github.com/input-output-hk/cardano-playground.git \
    && cd cardano-playground \
    && git sparse-checkout set docs/environments \
    && git checkout

# Step 3: Final Stage
# Declare ARG before FROM to allow its use in FROM
FROM ghcr.io/intersectmbo/cardano-db-sync:${DBSYNC_TAG}
COPY --from=json_update /app/update_json /bin/update_json
COPY --from=config /cardano-playground/docs/environments /environments
COPY ./entrypoint.sh /
ENTRYPOINT ["/bin/bash", "-e", "/entrypoint.sh"]