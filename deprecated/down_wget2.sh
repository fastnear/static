#!/usr/bin/env bash

# The script downloads the latest RPC snapshot from the FASTNEAR snapshot server.
# It uses wget2 for parallel downloads and retries failed downloads.
#
# Instructions:
# - Make sure you have wget2 installed, e.g. using `apt install wget2`
# - Set $DATA_PATH to the path where you want to download the snapshot (default: /root/.near/data)
# - Set $THREADS to the number of threads you want to use for downloading (default: 16).

set -e

if ! command -v wget2 &> /dev/null
then
    echo "wget2 is not installed. Please install it and try again."
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

  wget2 --base="$PREFIX/$LATEST/" \
        --input-file=$FILES_PATH \
        --directory-prefix=$DATA_PATH \
        --max-threads=$THREADS \
        --continue=on \
        --retry-connrefused=on \
        --tries=0 \
        --timeout=60 \
        --read-timeout=60 \
        --progress=bar

  ACTUAL_NUM_FILES=$(find $DATA_PATH -type f | wc -l)
  echo "Downloaded $ACTUAL_NUM_FILES files, expected $EXPECTED_NUM_FILES"

  if [[ $ACTUAL_NUM_FILES -ne $EXPECTED_NUM_FILES ]]; then
    echo "Error: Downloaded files count mismatch"
    exit 1
  fi
}

main "$@"
