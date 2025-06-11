# sort_products.rb
# This script sorts the products in a YAML file alphabetically by their 'key'.

require 'yaml'

# Define the path to the YAML file to be sorted.
file_path = 'products.yml'

# --- Error Handling ---
# Check if the specified file exists before attempting to read it.
unless File.exist?(file_path)
  puts "Error: The file '#{file_path}' was not found."
  exit
end

puts "Reading and parsing '#{file_path}'..."

# Read and parse the YAML file.
# YAML.load_file handles parsing the file content into Ruby objects.
products_data = YAML.load_file(file_path)

# Verify that the YAML file contains an array, which is the expected format.
unless products_data.is_a?(Array)
  puts "Error: The YAML file at '#{file_path}' does not contain an array."
  puts "The file should start with a list of products (e.g., '- key: ...')."
  exit
end

puts "Sorting products alphabetically by key..."

# --- Sorting Logic ---
# Sort the array of product hashes in place.
# The sort is based on the value of the 'key' for each product.
products_data.sort_by! { |product| product['key'] }

puts "Writing sorted data back to '#{file_path}'..."

# --- File Writing ---
# Write the sorted array back to the original file.
# The 'w' mode truncates the existing file before writing the new content.
File.open(file_path, 'w') do |file|
  # The to_yaml method serializes the Ruby array back into a YAML formatted string.
  # This includes the '---' document separator at the beginning.
  file.write(products_data.to_yaml)
end

puts "Successfully sorted '#{file_path}'."
