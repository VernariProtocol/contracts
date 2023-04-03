#!/bin/bash

# Check if the user provided the necessary arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 json_file key"
    exit 1
fi

JSON_FILE="$1"
KEY="$2"

# Check if the JSON file exists
if [ ! -f "$JSON_FILE" ]; then
    echo "Error: JSON file not found."
    exit 1
fi

# Retrieve the value from the JSON file using the key
VALUE=$(jq -r ".${KEY}" "$JSON_FILE")

if [ "$VALUE" == "null" ]; then
    echo "Error: Key not found in JSON file."
    exit 1
fi

echo $VALUE
