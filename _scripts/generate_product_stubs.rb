require 'yaml'
require 'fileutils'

# Define paths
project_root = File.expand_path('..', __dir__)
products_file = File.join(project_root, '_data', 'products.yml')
open_source_dir = File.join(project_root, '_open_source')
proprietary_dir = File.join(project_root, '_proprietary')

# Ensure output directories exist
FileUtils.mkdir_p(open_source_dir)
FileUtils.mkdir_p(proprietary_dir)

# Load product data
unless File.exist?(products_file)
  puts "Error: #{products_file} not found."
  exit 1
end

products = YAML.load_file(products_file)

unless products.is_a?(Array)
  puts "Error: #{products_file} is not a list of products."
  exit 1
end

puts "Processing #{products.count} products..."

products.each do |product|
  unless product.is_a?(Hash) && product.key?('key') && product.key?('license')
    puts "Skipping invalid product entry: #{product.inspect}"
    next
  end

  product_key = product['key']
  license_type = product['license']

  target_dir = case license_type
               when 'open_source'
                 open_source_dir
               when 'proprietary'
                 proprietary_dir
               else
                 puts "Skipping product '#{product_key}' with unknown license type: '#{license_type}'"
                 next
               end

  md_file_path = File.join(target_dir, "#{product_key}.md")

  if File.exist?(md_file_path)
    puts "Skipping '#{product_key}': #{md_file_path} already exists."
  else
    content = <<~MARKDOWN
      ---
      layout: product_detail
      key: #{product_key}
      ---
    MARKDOWN

    File.write(md_file_path, content)
    puts "Created: #{md_file_path}"
  end
end

puts "Done."
