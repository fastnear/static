#!/usr/bin/env bash

set -e

PREFIX="https://snapshot.neardata.xyz/mainnet/rpc"
: "${THREADS:=16}"
: "${DATA_PATH:=/root/.near/data}"

mkdir -p $DATA_PATH
LATEST=$(curl -s "$PREFIX/latest.txt")
echo "Latest snapshot block: $LATEST"

wget -q "$PREFIX/$LATEST/files.txt" -O /tmp/files.txt

EXPECTED_NUM_FILES=$(wc -l < /tmp/files.txt)

echo "Creating sub-directories"
while IFS= read -r FILE; do
  DIR=$(dirname "$FILE")
  if [ "$DIR" != "." ]; then
    mkdir -p "$DATA_PATH/$DIR"
  fi
done < /tmp/files.txt

echo "Downloading $EXPECTED_NUM_FILES files with $THREADS threads"
cat /tmp/files.txt | xargs -P $THREADS -I {} bash -c 'echo "$1" && wget --tries=5 --waitretry=1 --retry-connrefused -q -c "'$PREFIX'/'$LATEST'/$1" -O "'$DATA_PATH'/$1"' bash {}

ACTUAL_NUM_FILES=$(find $DATA_PATH -type f | wc -l)
echo "Downloaded $ACTUAL_NUM_FILES files, expected $EXPECTED_NUM_FILES"

if [[ $ACTUAL_NUM_FILES -ne $EXPECTED_NUM_FILES ]]; then
  echo "Error: Downloaded files count mismatch"
  exit 1
fi
