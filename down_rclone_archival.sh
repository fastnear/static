#!/usr/bin/env bash
set -e

# The script downloads the Archival snapshot from the FASTNEAR snapshots.
# It uses rclone for parallel downloads and retries failed downloads.
#
# Instructions:
# - Make sure you have rclone installed, e.g. using `sudo -v ; curl https://rclone.org/install.sh | sudo bash`
# - Set $CHAIN_ID to either mainnet or testnet (default: mainnet)
# - Set $THREADS to the number of threads you want to use for downloading. Use 128 for 10Gbps, and 16 for 1Gbps (default: 128).
# - Set $TPSLIMIT to the maximum number of HTTP new actions per second. (default: 4096)
# - Set $DATA_TYPE to either `hot-data` or `cold-data` (default: cold-data)
# - Set $BWLIMIT to the maximum bandwidth to use for download in case you want to limit it. (default: 10G)
# - Set $DATA_PATH to the path where you want to download the snapshot (default: /mnt/nvme/data/$DATA_TYPE)
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
: "${DATA_TYPE:=cold-data}"
: "${DATA_PATH:=/mnt/nvme/data/$DATA_TYPE}"
: "${BWLIMIT:=10G}"

PREFIX="$CHAIN_ID/archival"

LATEST=$(curl -s "$HTTP_URL/$PREFIX/latest.txt")
echo "Latest snapshot block: $LATEST"

: "${BLOCK:=$LATEST}"

main() {
  mkdir -p "$DATA_PATH"
  echo "Snapshot block: $BLOCK"

  FILES_PATH="/tmp/files.txt"
  curl -s "$HTTP_URL/$PREFIX/$BLOCK/$DATA_TYPE/files.txt" -o $FILES_PATH

  EXPECTED_NUM_FILES=$(wc -l < $FILES_PATH)
  echo "Downloading $EXPECTED_NUM_FILES files with $THREADS threads"

  rclone copy \
    --no-traverse \
    --multi-thread-streams 1 \
    --tpslimit $TPSLIMIT \
    --bwlimit $BWLIMIT \
    --max-backlog 1000000 \
    --transfers $THREADS \
    --checkers 128 \
    --buffer-size 128M \
    --http-url $HTTP_URL \
    --files-from=$FILES_PATH \
    --retries 20 \
    --retries-sleep 1s \
    --low-level-retries 10 \
    --progress \
    --stats-one-line \
    :http:$PREFIX/$BLOCK/$DATA_TYPE/ $DATA_PATH

  ACTUAL_NUM_FILES=$(find $DATA_PATH -type f | wc -l)
  echo "Downloaded $ACTUAL_NUM_FILES files, expected $EXPECTED_NUM_FILES"

  if [[ $ACTUAL_NUM_FILES -ne $EXPECTED_NUM_FILES ]]; then
    echo "Error: Downloaded files count mismatch"
    exit 1
  fi
}

main "$@"
