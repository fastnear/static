#!/usr/bin/env bash
set -e

# The script updates the neard config with the latest boot nodes and sets the state sync bucket to "fast-state-parts".
# Usage: ./update_boot_nodes.sh chain_id [config_path]

CHAIN_ID=$1
CONFIG_PATH=$2

# Verify that the chain ID is set to either mainnet or testnet
if [ "$CHAIN_ID" != "mainnet" ] && [ "$CHAIN_ID" != "testnet" ]; then
  echo "Usage: $0 chain_id [config_path]"
  echo "Please set the chain ID to either mainnet or testnet."
  exit 1
fi

if [ -z "$CONFIG_PATH" ]; then
  CONFIG_PATH=~/.near/config.json
fi

export BOOT_NODES=`curl -s -X POST https://rpc.$CHAIN_ID.fastnear.com \  -H "Content-Type: application/json" \
  -d '{
        "jsonrpc": "2.0",
        "method": "network_info",
        "params": [],
        "id": "dontcare"
      }' | \
jq '.result.active_peers as $list1 | .result.known_producers as $list2 |
$list1[] as $active_peer | $list2[] |
select(.peer_id == $active_peer.id) |
"\(.peer_id)@\($active_peer.addr)"' |\
awk 'NR>2 {print ","} length($0) {print p} {p=$0}' ORS="" | sed 's/"//g'`

echo "New boot nodes: $BOOT_NODES"

cat <<< $(jq '.network.boot_nodes = "'$BOOT_NODES'" | .state_sync.sync.ExternalStorage.location.GCS.bucket = "fast-state-parts"' $CONFIG_PATH) > $CONFIG_PATH
