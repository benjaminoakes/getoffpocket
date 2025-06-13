require 'yaml'
require 'fileutils'

# Define paths
project_root = File.expand_path('..', __dir__)
products_file_path = File.join(project_root, '_data', 'products.yml')

# Load product data
unless File.exist?(products_file_path)
  puts "Error: #{products_file_path} not found."
  exit 1
end

products_data = YAML.load_file(products_file_path)

unless products_data.is_a?(Array)
  puts "Error: #{products_file_path} is not a list of products."
  exit 1
end

puts "Processing #{products_data.count} products..."

updated_count = 0

products_data.each do |product|
  unless product.is_a?(Hash) && product.key?('key')
    puts "Skipping invalid product entry: #{product.inspect}"
    next
  end

  if product.key?('data_verification')
    puts "Product '#{product['key']}' already has 'data_verification: #{product['data_verification']}'. Skipping."
  else
    product['data_verification'] = 'none'
    puts "Added 'data_verification: \"none\"' to product '#{product['key']}'."
    updated_count += 1
  end
end

if updated_count > 0
  # Write the updated data back to the file
  File.open(products_file_path, 'w') do |file|
    file.write("# This file is automatically managed. Manual edits might be overwritten.\n")
    # Dump the entire array as YAML, which handles formatting correctly
    file.write(YAML.dump(products_data))
  end
  puts "Successfully updated #{products_file_path} with 'data_verification' attributes for #{updated_count} products."
else
  puts "No products needed updating."
end

puts "Done."
