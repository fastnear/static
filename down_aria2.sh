#!/usr/bin/env bash

# The script downloads the latest RPC snapshot from the FASTNEAR snapshot server.
# It uses aria2 for parallel downloads and retries failed downloads.
#
# Instructions:
# - Make sure you have aria2 installed, e.g. using `apt install aria2`
# - Set $DATA_PATH to the path where you want to download the snapshot (default: /root/.near/data)
# - Set $THREADS to the number of threads you want to use for downloading (default: 16).

set -e

if ! command -v aria2c &> /dev/null
then
    echo "aria2c is not installed. Please install it and try again."
    exit 1
fi

PREFIX="https://snapshot.neardata.xyz/mainnet/rpc"
: "${THREADS:=16}"
: "${DATA_PATH:=/root/.near/data}"

main() {
  mkdir -p "$DATA_PATH"
  LATEST=$(curl -s "$PREFIX/latest.txt")
  echo "Latest snapshot block: $LATEST"

  FILES_PATH="/tmp/files.txt"
  curl -s "$PREFIX/$LATEST/files.txt" -o $FILES_PATH

  EXPECTED_NUM_FILES=$(wc -l < $FILES_PATH)
  echo "Downloading $EXPECTED_NUM_FILES files with $THREADS threads"

  aria2c --split=4 --max-connection-per-server=$THREADS --min-split-size=80M \
         --max-concurrent-downloads=$THREADS --connect-timeout=60 --retry-wait=1 \
         --max-tries=100 \
         --continue=true \
         --dir=$DATA_PATH --auto-file-renaming=false \
         --download-result=full --optimize-concurrent-downloads=true \
         --conditional-get=true --allow-overwrite=true \
         --file-allocation=none \
         --download-result=hide \
         -j $THREADS \
         --input-file=<(awk '{print "'$PREFIX'/'$LATEST'/" $1 "\n\t" "out=" $1}' $FILES_PATH)

  ACTUAL_NUM_FILES=$(find $DATA_PATH -type f | wc -l)
  echo "Downloaded $ACTUAL_NUM_FILES files, expected $EXPECTED_NUM_FILES"

  if [[ $ACTUAL_NUM_FILES -ne $EXPECTED_NUM_FILES ]]; then
    echo "Error: Downloaded files count mismatch"
    exit 1
  fi
}

main "$@"

}
