set -euo pipefail

# URL of the GTFS feed (symlink to the latest schedule)
GTFS_URL="https://gtfs.openov.nl/gtfs-nl.zip"
GTFS_URL="https://gtfs.ovapi.nl/nl/gtfs-nl.zip"

# Output file
OUT_FILE="gtfs-nl.zip"

# Metadata files
ETAG_FILE="${OUT_FILE}.etag"
LM_FILE="${OUT_FILE}.lastmod"

# Identify yourself, required by OpenOV
USER_AGENT="PatrickSteil-GTFS-Downloader/1.0"

# Build curl conditional header args dynamically
CURL_HEADERS=(
  -A "$USER_AGENT"
  -D -
  -L
  --fail
  --silent --show-error
)

# Add If-None-Match header if ETag exists
if [[ -f "$ETAG_FILE" ]]; then
  ETAG=$(cat "$ETAG_FILE")
  CURL_HEADERS+=( -H "If-None-Match: $ETAG" )
fi

# Add If-Modified-Since header if Last-Modified exists
if [[ -f "$LM_FILE" ]]; then
  LASTMOD=$(cat "$LM_FILE")
  CURL_HEADERS+=( -H "If-Modified-Since: $LASTMOD" )
fi

# Temporary files
TMP_ZIP="${OUT_FILE}.tmp"
TMP_HEADERS="${OUT_FILE}.headers.tmp"

# Download with headers captured
curl "${CURL_HEADERS[@]}" "$GTFS_URL" -o "$TMP_ZIP" > "$TMP_HEADERS" 2>/dev/null || true

# Extract HTTP status code
STATUS=$(grep -m1 "HTTP/" "$TMP_HEADERS" | awk '{print $2}')

if [[ "$STATUS" == "304" ]]; then
  echo "No update available (HTTP 304). Keeping existing file."
  rm -f "$TMP_HEADERS" "$TMP_ZIP"
  exit 0
elif [[ "$STATUS" != "200" ]]; then
  echo "Unexpected HTTP status: $STATUS"
  rm -f "$TMP_HEADERS" "$TMP_ZIP"
  exit 1
fi

# Save new ETag
NEW_ETAG=$(grep -i "^ETag:" "$TMP_HEADERS" | sed 's/ETag:[[:space:]]*//I')
if [[ -n "$NEW_ETAG" ]]; then
  echo "$NEW_ETAG" > "$ETAG_FILE"
fi

# Save new Last-Modified
NEW_LASTMOD=$(grep -i "^Last-Modified:" "$TMP_HEADERS" | sed 's/Last-Modified:[[:space:]]*//I')
if [[ -n "$NEW_LASTMOD" ]]; then
  echo "$NEW_LASTMOD" > "$LM_FILE"
fi

# Replace old file atomically
mv "$TMP_ZIP" "$OUT_FILE"
rm -f "$TMP_HEADERS"

echo "Downloaded updated GTFS feed: $OUT_FILE"

