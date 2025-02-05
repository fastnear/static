#!/usr/bin/env bash
set -e

# The script downloads the RPC snapshot from the FASTNEAR snapshots.
# It uses rclone for parallel downloads and retries failed downloads.
#
# Instructions:
# - Make sure you have rclone installed, e.g. using `sudo -v ; curl https://rclone.org/install.sh | sudo bash`
# - Set $CHAIN_ID to either mainnet or testnet (default: mainnet)
# - Set $THREADS to the number of threads you want to use for downloading. Use 128 for 10Gbps, and 16 for 1Gbps (default: 128).
# - Set $TPSLIMIT to the maximum number of HTTP new actions per second. (default: 4096)
# - Set $BWLIMIT to the maximum bandwidth to use for download in case you want to limit it. (default: 10G)
# - Set $DATA_PATH to the path where you want to download the snapshot (default: ~/.near/data)
# - Set $RPC_TYPE to either `rpc` or `fast-rpc` (default: rpc). `fast-rpc` is the 3 epochs and trimmed headers. `rpc` is 5 epochs and all headers.
# - Set $BLOCK to the block height of the snapshot you want to download. If not set, it will download the latest snapshot.

if ! type rclone >/dev/null 2>&1
then
    echo "rclone is not installed. Please install it and try again."
    exit 1
fi

HTTP_URL="https://snapshot.neardata.xyz"
: "${CHAIN_ID:=mainnet}"
: "${THREADS:=128}"
: "${TPSLIMIT:=4096}"
: "${BWLIMIT:=10G}"
: "${RPC_TYPE:=rpc}"
: "${DATA_PATH:=~/.near/data}"
: "${RETRIES:=20}"
: "${CHECKERS:=$THREADS}"
: "${LOW_LEVEL_RETRIES:=10}"

PREFIX="$CHAIN_ID/$RPC_TYPE"
HTTP_NO_HEAD_FLAG=""

LATEST=$(curl -s "$HTTP_URL/$PREFIX/latest.txt")
echo "Latest snapshot block: $LATEST"

: "${BLOCK:=$LATEST}"

main() {
  mkdir -p "$DATA_PATH"
  echo "Snapshot block: $BLOCK"

  if [ -z "$(find "$DATA_PATH" -maxdepth 1 -not -name '.' -not -name '..' -print -quit)" ]; then
      HTTP_NO_HEAD_FLAG="--http-no-head"
  fi

  FILES_PATH="/tmp/files.txt"
  curl -s "$HTTP_URL/$PREFIX/$BLOCK/files.txt" -o $FILES_PATH

  EXPECTED_NUM_FILES=$(wc -l < $FILES_PATH)
  echo "Downloading $EXPECTED_NUM_FILES files with $THREADS threads"

  rclone copy \
    --no-traverse \
    --multi-thread-streams 1 \
    --tpslimit $TPSLIMIT \
    --bwlimit $BWLIMIT \
    --max-backlog 1000000 \
    --transfers $THREADS \
    --checkers $CHECKERS \
    --buffer-size 128M \
    --http-url $HTTP_URL \
    --files-from=$FILES_PATH \
    --retries $RETRIES \
    --retries-sleep 1s \
    --low-level-retries $LOW_LEVEL_RETRIES \
    --progress \
    --stats-one-line \
    :http:$PREFIX/$BLOCK/ $DATA_PATH

  ACTUAL_NUM_FILES=$(find $DATA_PATH -type f | wc -l)
  echo "Downloaded $ACTUAL_NUM_FILES files, expected $EXPECTED_NUM_FILES"

  if [[ $ACTUAL_NUM_FILES -ne $EXPECTED_NUM_FILES ]]; then
    echo "Error: Downloaded files count mismatch"
    exit 1
  fi
}

main "$@"
