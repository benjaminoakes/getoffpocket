#!/bin/bash

# This script downloads icons specified in the Jekyll data files.

# Ensure the output directory exists
mkdir -p icons
echo "Created 'icons/' directory."

# Combine both data files for processing
cat _data/open_source.yml _data/proprietary.yml | \
# Filter for lines containing 'key:' or 'icon:'
grep -E '^\s*-\s*key:|\s*icon:' | \
# Remove leading whitespace and '- ' for easier parsing
sed -e 's/^[ \t-]*//' | \
while read -r line; do
  # Check if the line contains a key
  if [[ $line == key:* ]]; then
    # Extract the key value (e.g., "wallabag")
    current_key=$(echo "$line" | sed 's/key: //')
  fi
  
  # Check if the line contains an icon URL
  if [[ $line == icon:* ]]; then
    # Extract the icon URL
    icon_url=$(echo "$line" | sed 's/icon: //')
    
    # Check if it's a valid HTTP/HTTPS URL and not an emoji
    if [[ $icon_url == http* ]]; then
      # Determine the file extension from the end of the URL
      # This handles cases like '.../file.jpeg/512x512bb.jpg' -> 'jpg'
      extension="${icon_url##*.}"
      # Clean up any query parameters from the extension
      extension="${extension%%\?*}"
      
      # Set the output filename
      output_file="icons/${current_key}.${extension}"
      
      echo "Downloading icon for '${current_key}' -> ${output_file}"
      # Download the file using curl, -L follows redirects, -s is silent, -o specifies output
      curl -L -s -o "$output_file" "$icon_url"
    else
      echo "Skipping non-URL icon for '${current_key}'."
    fi
  fi
done

echo ""
echo "Icon download process complete. Check the 'icons/' directory."
