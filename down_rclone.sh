set -e

# The script downloads the latest RPC snapshot from the FASTNEAR snapshot server.
# It uses rclone for parallel downloads and retries failed downloads.
#
# Instructions:
# - Make sure you have rclone installed, e.g. using `apt install rclone`
# - Set $DATA_PATH to the path where you want to download the snapshot (default: /root/.near/data)
# - Set $THREADS to the number of threads you want to use for downloading (default: 16).

if ! command -v rclone &> /dev/null
then
    echo "rclone is not installed. Please install it and try again."
    exit 1
fi

HTTP_URL="https://snapshot.neardata.xyz"
PREFIX="mainnet/rpc"
: "${THREADS:=16}"
: "${DATA_PATH:=/root/.near/data}"

main() {
  mkdir -p "$DATA_PATH"
  LATEST=$(curl -s "$HTTP_URL/$PREFIX/latest.txt")
  echo "Latest snapshot block: $LATEST"

  FILES_PATH="/tmp/files.txt"
  curl -s "$HTTP_URL/$PREFIX/$LATEST/files.txt" -o $FILES_PATH

  EXPECTED_NUM_FILES=$(wc -l < $FILES_PATH)
  echo "Downloading $EXPECTED_NUM_FILES files with $THREADS threads"

  rclone copy \
    --no-traverse \
    --http-no-head \
    --transfers $THREADS \
    --checkers $THREADS \
    --buffer-size 128M \
    --http-url $HTTP_URL \
    --files-from=$FILES_PATH \
    --retries 10 \
    --retries-sleep 1s \
    --low-level-retries 10 \
    --progress \
    :http:$PREFIX/$LATEST/ $DATA_PATH

  ACTUAL_NUM_FILES=$(find $DATA_PATH -type f | wc -l)
  echo "Downloaded $ACTUAL_NUM_FILES files, expected $EXPECTED_NUM_FILES"

  if [[ $ACTUAL_NUM_FILES -ne $EXPECTED_NUM_FILES ]]; then
    echo "Error: Downloaded files count mismatch"
    exit 1
  fi
}

main "$@"
