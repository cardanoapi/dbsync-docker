FROM ubuntu:24.04 as config
RUN apt-get update && apt-get install -y git \
    && git clone --depth 1 --filter=blob:none --sparse --no-checkout https://github.com/input-output-hk/cardano-playground.git \
    && cd cardano-playground \
    && git sparse-checkout set docs/environments \
    && git checkout

FROM ghcr.io/intersectmbo/cardano-db-sync:13.6.0.4
COPY --from=config /cardano-playground/docs/environments /environments
COPY ./entrypoint.sh ./update_json_keys.sh /
ENTRYPOINT ["/bin/bash", "-e", "/entrypoint.sh" ]