#!/bin/bash

# Check if the user provided the necessary arguments
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 json_file key value"
    exit 1
fi

JSON_FILE="$1"
KEY="$2"
VALUE="$3"

# Check if the JSON file exists
if [ ! -f "$JSON_FILE" ]; then
    echo "Error: JSON file not found."
    exit 1
fi

# Add the key-value pair to the JSON file
jq ". + {\"$KEY\": \"$VALUE\"}" "$JSON_FILE" >"$JSON_FILE.tmp" && mv "$JSON_FILE.tmp" "$JSON_FILE"
echo "Added $KEY with value $VALUE to $JSON_FILE"
