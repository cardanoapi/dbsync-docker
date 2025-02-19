#!/bin/bash

# Generated with chatgpt
# Function to update keys in destination JSON using source JSON
update_json_keys() {
    source_file=$1
    dest_file=$2
    output_file=$3

    # Check if jq is installed
    if ! command -v jq &> /dev/null
    then
        echo "jq command not found, please install jq."
        exit 1
    fi

    # Read the source file into a variable
    src=$(cat "$source_file")

    # Use jq to replace keys in the destination file with those from the source file
    jq --argjson src "$src" 'to_entries | map(.key as $key | if $src[$key] then {key: $key, value: $src[$key]} else . end) | from_entries' "$dest_file" > "$output_file"
    echo "Updated JSON saved to $output_file"
}

# Check if correct number of arguments is passed
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <source_json> <destination_json> <output_json>"
    exit 1
fi

# Run the function with passed arguments
update_json_keys "$1" "$2" "$3"
