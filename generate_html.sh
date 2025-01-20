#!/bin/bash

TEMPLATE_FILE=$1
OUTPUT_FILE=$2
URL=$3

# Detect the base URL
BASE_URL=${BASE_URL:-http://localhost:3000}
API_BASE_URL=${API_BASE_URL:-http://localhost:8888}

# Extract metadata for the URL using Python to parse JSON
OG_TITLE=$(python3 -c "import sys, json; print(json.load(sys.stdin)['$URL']['og_title'])" < metatags.json)
OG_DESCRIPTION=$(python3 -c "import sys, json; print(json.load(sys.stdin)['$URL']['og_description'])" < metatags.json)
OG_IMAGE_PATH=$(python3 -c "import sys, json; print(json.load(sys.stdin)['$URL']['og_image_path'])" < metatags.json)
OG_IMAGE_ALT=$(python3 -c "import sys, json; print(json.load(sys.stdin)['$URL']['og_image_alt'])" < metatags.json)
OG_IMAGE_WIDTH=$(python3 -c "import sys, json; print(json.load(sys.stdin)['$URL']['og_image_width'])" < metatags.json)
OG_IMAGE_HEIGHT=$(python3 -c "import sys, json; print(json.load(sys.stdin)['$URL']['og_image_height'])" < metatags.json)

# Escape special characters for sed
escape_sed() {
    echo "$1" | sed -e 's/[\/&]/\\&/g'
}

BASE_URL_ESCAPED=$(escape_sed "$BASE_URL")
API_BASE_URL_ESCAPED=$(escape_sed "$API_BASE_URL")
OG_TITLE_ESCAPED=$(escape_sed "$OG_TITLE")
OG_DESCRIPTION_ESCAPED=$(escape_sed "$OG_DESCRIPTION")
OG_IMAGE_PATH_ESCAPED=$(escape_sed "$OG_IMAGE_PATH")
OG_IMAGE_ALT_ESCAPED=$(escape_sed "$OG_IMAGE_ALT")
OG_IMAGE_WIDTH_ESCAPED=$(escape_sed "$OG_IMAGE_WIDTH")
OG_IMAGE_HEIGHT_ESCAPED=$(escape_sed "$OG_IMAGE_HEIGHT")
OG_URL_PATH_ESCAPED=$(escape_sed "$URL")

# Replace placeholders in the template
cat $TEMPLATE_FILE \
    | sed "s/{{ base_url }}/$BASE_URL_ESCAPED/g" \
    | sed "s/{{ api_base_url }}/$API_BASE_URL_ESCAPED/g" \
    | sed "s/{{ og_title }}/$OG_TITLE_ESCAPED/g" \
    | sed "s/{{ og_description }}/$OG_DESCRIPTION_ESCAPED/g" \
    | sed "s/{{ og_image_path }}/$OG_IMAGE_PATH_ESCAPED/g" \
    | sed "s/{{ og_image_alt }}/$OG_IMAGE_ALT_ESCAPED/g" \
    | sed "s/{{ og_image_width }}/$OG_IMAGE_WIDTH_ESCAPED/g" \
    | sed "s/{{ og_image_height }}/$OG_IMAGE_HEIGHT_ESCAPED/g" \
    | sed "s,{{ og_url_path }},$OG_URL_PATH_ESCAPED,g" > $OUTPUT_FILE