#!/bin/bash
set -euo pipefail

### generate pgpass file

gen_pgpass="$(find /nix/store  -maxdepth 1 -name '*gen-pgpass' -print -quit)"
export PGPASSFILE=/configuration/pgpass
$gen_pgpass


### set libpq env variables

export PGHOST=$(cut -d ":" -f 1 "${PGPASSFILE}")
export PGPORT=$(cut -d ":" -f 2 "${PGPASSFILE}")
export PGDATABASE=$(cut -d ":" -f 3 "${PGPASSFILE}")
user=$(cut -d ":" -f 4 "${PGPASSFILE}")
if [ "$user" != "*" ]; then
  export PGUSER=$user
fi;


export CARDANO_NODE_SOCKET_PATH="/node-ipc/node.socket"

WAIT_FOR_NODE_SYNC=$(echo -n "${WAIT_FOR_NODE_SYNC:-}" | tr '[:upper:]' '[:lower:]')


if [[ "${WAIT_FOR_NODE_SYNC,,}" =~ ^(y|yes|1|true)$ ]]; then
  until [ -S $CARDANO_NODE_SOCKET_PATH ]; do
    echo Waiting for $CARDANO_NODE_SOCKET_PATH
    sleep 10
  done


  DB_MAX_BLOCK=$(psql -h $PGHOST $PGDATABASE -U $PGUSER -t -c 'select max (block_no) from block;')
    # Ensure DB_MAX_BLOCK is a valid integer, if not, exit with an error
    if ! [[ "$DB_MAX_BLOCK" =~ ^[0-9]+$ ]]; then
      echo "Block in db:"$DB_MAX_BLOCK
      DB_MAX_BLOCK=0
    fi
  NODE_CUR_BLOCK=0
  while [ $NODE_CUR_BLOCK -lt $DB_MAX_BLOCK ]; do
    NODE_STATUS="$(cardano-cli query tip --mainnet 2>/dev/null || true)"
    NODE_CUR_BLOCK="$(jq -e -r '.block' <<<"$NODE_STATUS" 2>/dev/null || true)"
    echo "Waiting... Sync progress at $NODE_CUR_BLOCK /$DB_MAX_BLOCK"
    sleep 10
  done
fi

mkdir -p log-dir
if [[ "${DISABLE_LEDGER:-N}" == "Y" ]]; then
  LEDGER_OPTS="--disable-ledger"
else
  LEDGER_OPTS="--state-dir /var/lib/cexplorer"
fi


### set configuration home based on the network

CONFIG_HOME="/environments"
if [ -z "${NETWORK:-}" ]; then
  echo "NETWORK is not set, defaulting to mainnet"
  NETWORK="mainnet"
else
  IS_NETWORK_ENV_SET="1"
  echo "NETWORK is set to $NETWORK"
fi

# Convert NETWORK to lowercase
NETWORK=$(echo "$NETWORK" | tr '[:upper:]' '[:lower:]')

if [ ! -d "$CONFIG_HOME/$NETWORK" ]; then
  echo "Invalid network: $NETWORK"
  ## list known networks
  echo "Known networks are:"
  ls -1 $CONFIG_HOME
  exit 1
  
fi



if [[ -z "${DB_SYNC_CONFIG:-}" ]]; then
  DB_SYNC_CONFIG="$CONFIG_HOME/$NETWORK"

elif [[ -z "${IS_NETWORK_ENV_SET:-}" ]]; then # dbsync config is set and network is not
  DB_SYNC_CONFIG="$CONFIG_HOME/$NETWORK"

else  ## both NETWORK and DB_SYNC_CONFIG are set

  MERGED_CONFIG="$CONFIG_HOME/$NETWORK/merged-config.json"
  # take the keys from config file and replace i the original config.
  ./update_json_keys.sh "$DB_SYNC_CONFIG" \
      "$CONFIG_HOME/$NETWORK" \
      "$MERGED_CONFIG"
  DB_SYNC_CONFIG="$MERGED_CONFIG"
fi


SCHEMA_DIR=$(find /nix/store -maxdepth 1 -type d -name '*-schema' -print -quit)


echo '>' cardano-db-sync \
  --config "$DB_SYNC_CONFIG" \
  --socket-path "$CARDANO_NODE_SOCKET_PATH" \
  --schema-dir ${SCHEMA_DIR} \
  ${LEDGER_OPTS} \
  ${EXTRA_DB_SYNC_ARGS:-}

exec cardano-db-sync \
  --config "$DB_SYNC_CONFIG" \
  --socket-path "$CARDANO_NODE_SOCKET_PATH" \
  --schema-dir ${SCHEMA_DIR} \
  ${LEDGER_OPTS} \
  ${EXTRA_DB_SYNC_ARGS:-}
