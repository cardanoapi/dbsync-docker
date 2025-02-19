FROM ubuntu:24.04 as config
RUN apt-get update && apt-get install -y git \
    && git clone --depth 1 --filter=blob:none --sparse --no-checkout https://github.com/IntersectMBO/cardano-world.git \
    && cd cardano-world \
    && git sparse-checkout set docs/environments \
    && git checkout

FROM ghcr.io/intersectmbo/cardano-db-sync:13.6.0.4
COPY --from=config /cardano-world/docs/environments /environments
COPY ./entrypoint.sh ./update_json_keys.sh /
ENTRYPOINT ["/bin/sh" "-e" "/entrypoint.sh" ]