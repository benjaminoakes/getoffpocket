#!/usr/bin/env ruby

require 'yaml'
require 'net/http'
require 'uri'
require 'fileutils'

# --- Configuration ---
PRODUCTS_FILE = '_data/products.yml'
OUTPUT_DIR = 'icons'

# --- Helper Methods ---

# Fetches a file from a URL, handling redirects, and saves it to a destination.
# @param url_string [String] The URL to download the file from.
# @param destination_path [String] The local path to save the file to.
def download_icon(url_string, destination_path)
  uri = URI.parse(url_string)

  # Function to perform the HTTP GET request, with a redirect limit.
  fetch = ->(http_uri, limit = 5) {
    raise "Too many redirects" if limit.zero?

    response = Net::HTTP.get_response(http_uri)

    case response
    when Net::HTTPSuccess
      response
    when Net::HTTPRedirection
      location = response['location']
      new_uri = URI.join(http_uri.to_s, location)
      puts "  -> Redirected to #{new_uri}"
      fetch.(new_uri, limit - 1) # Recursive call to follow redirect
    else
      # Raises an error for non-successful responses (e.g., 404, 500)
      response.value
    end
  }

  begin
    response = fetch.(uri)
    # Ensure the directory for the icon exists
    FileUtils.mkdir_p(File.dirname(destination_path))
    # Write the downloaded content to the file
    File.open(destination_path, 'wb') do |file|
      file.write(response.body)
    end
    puts "  -> ✅ Successfully downloaded to '#{destination_path}'."
  rescue StandardError => e
    puts "  -> ❌ Error downloading from #{url_string}: #{e.message}"
  end
end

# --- Main Script Logic ---

def main
  unless File.exist?(PRODUCTS_FILE)
    puts "Error: Products file not found at '#{PRODUCTS_FILE}'"
    return
  end

  # Load the list of products from the YAML file.
  products = YAML.load_file(PRODUCTS_FILE)

  puts "--- Checking and Downloading Icons for Products ---"

  products.each do |product|
    name = product['name']
    icon_path = product['icon']
    source_url = product['source_icon_url']

    puts "\n🔍 Processing '#{name}'..."

    # Validate that the necessary keys exist and are valid.
    if icon_path.nil? || icon_path.strip.empty?
      puts "  -> 🟡 Skipping: 'icon' path is missing or empty."
      next
    end

    if source_url.nil? || !source_url.start_with?('http')
      puts "  -> 🟡 Skipping: 'source_icon_url' is missing or not a valid URL."
      next
    end

    # Check if the icon file already exists locally.
    if File.exist?(icon_path)
      puts "  -> 👍 Icon already exists at '#{icon_path}'. Skipping download."
    else
      puts "  -> ⚠️ Icon not found locally. Attempting to download..."
      download_icon(source_url, icon_path)
    end
  end

  puts "\n--- Icon check and download process complete. ---"
end

# --- Script Execution ---
if __FILE__ == $PROGRAM_NAME
  main
end
