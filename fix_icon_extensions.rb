#!/usr/bin/env ruby

require 'yaml'
require 'net/http'
require 'uri'

# --- Configuration ---
PRODUCTS_FILE = '_data/products.yml'

# A mapping from MIME types to the desired file extensions.
MIME_TYPE_TO_EXTENSION = {
  'image/jpeg' => '.jpg',
  'image/png'  => '.png',
  'image/gif'  => '.gif',
  'image/svg+xml' => '.svg',
  'image/x-icon' => '.ico',
  'image/webp' => '.webp'
}.freeze

# --- Helper Methods ---

# Fetches the Content-Type of a URL using a HEAD request.
# @param url_string [String] The URL to check.
# @return [String, nil] The Content-Type or nil if an error occurs.
def get_content_type(url_string)
  uri = URI.parse(url_string)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = (uri.scheme == 'https')
  http.open_timeout = 10
  http.read_timeout = 10

  begin
    response = http.request_head(uri.request_uri)
    if response.is_a?(Net::HTTPSuccess)
      return response['content-type']
    elsif response.is_a?(Net::HTTPRedirection)
      new_location = response['location']
      new_uri = URI.join(uri, new_location)
      puts "  -> Redirected to #{new_uri}"
      return get_content_type(new_uri.to_s)
    else
      puts "  -> ❌ HTTP Error: #{response.code} #{response.message}"
      return nil
    end
  rescue StandardError => e
    puts "  -> ❌ Error fetching headers from #{url_string}: #{e.message}"
    return nil
  end
end

# --- Main Script Logic ---

def main
  unless File.exist?(PRODUCTS_FILE)
    puts "Error: Products file not found at '#{PRODUCTS_FILE}'"
    return
  end

  products = YAML.load_file(PRODUCTS_FILE)
  updated = false

  puts "--- Checking and Fixing Icon Extensions ---"

  products.each do |product|
    name = product['name']
    icon_path = product['icon']
    source_url = product['source_icon_url']

    puts "\n🔍 Processing '#{name}'..."

    if source_url.nil? || !source_url.start_with?('http')
      puts "  -> 🟡 Skipping: 'source_icon_url' is missing or invalid."
      next
    end

    if icon_path.nil? || icon_path.strip.empty?
      puts "  -> 🟡 Skipping: 'icon' path is missing."
      next
    end

    # Get the actual content type from the source URL
    content_type = get_content_type(source_url)
    if content_type.nil?
      puts "  -> 🟡 Skipping: Could not determine content type."
      next
    end

    # Normalize content type (e.g., "image/jpeg; charset=utf-8" -> "image/jpeg")
    normalized_content_type = content_type.split(';').first.strip
    correct_extension = MIME_TYPE_TO_EXTENSION[normalized_content_type]

    if correct_extension.nil?
      puts "  -> 🟡 Skipping: Unsupported content type '#{normalized_content_type}'."
      next
    end

    current_extension = File.extname(icon_path)
    if current_extension.downcase != correct_extension.downcase
      new_icon_path = "icons/#{File.basename(icon_path, '.*')}#{correct_extension}"
      puts "  -> ❗️ Extension mismatch for '#{name}'."
      puts "     Current: '#{current_extension}', Correct: '#{correct_extension}'"
      puts "  -> Fixing: Changing '#{icon_path}' to '#{new_icon_path}'"
      product['icon'] = new_icon_path
      updated = true
    else
      puts "  -> ✅ Icon extension is correct."
    end
  end

  if updated
    File.open(PRODUCTS_FILE, 'w') do |file|
      file.write(products.to_yaml)
    end
    puts "\n--- ✅ Products file has been updated with corrected icon extensions. ---"
  else
    puts "\n--- 👍 All icon extensions are already correct. No changes made. ---"
  end
end

# --- Script Execution ---
if __FILE__ == $0
  main
end
