#!/bin/bash

# Check if file path is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <file_path>"
    exit 1
fi

file="$1"

# Create backup of original file
cp "$file" "${file}.bak"

# Remove comments matching pattern // @[...] using sed
sed -i 's/\s*\/\/ @\[.*\]$//' "$file"

# Remove any resulting empty lines
sed -i '/^[[:space:]]*$/d' "$file"

echo "Comments removed. Original file backed up as ${file}.bak"