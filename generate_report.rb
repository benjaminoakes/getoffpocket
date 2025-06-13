# generate_report.rb
# This script reads product data from a YAML file and formats it into a
# detailed report suitable for analysis.

require 'yaml'
require 'time'

# --- Configuration ---
# Define the path to the YAML file containing the product data.
PRODUCTS_FILE_PATH = '_data/products.yml'

# --- File Handling ---
# Check for the existence of the products file before proceeding.
unless File.exist?(PRODUCTS_FILE_PATH)
  puts "Error: The product data file was not found at '#{PRODUCTS_FILE_PATH}'."
  exit
end

# Load the product data from the specified YAML file.
# The YAML.load_file method parses the file content into Ruby objects (arrays and hashes).
products = YAML.load_file(PRODUCTS_FILE_PATH)

# --- Report Generation ---
# Begin the report with a main title and a timestamp for when the report was generated.
puts "# Product Report for Gemini Deep Research"
puts "Generated on: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
puts "\n---\n"

# Iterate over each product in the data file to generate its section in the report.
products.each do |product|
  # Use the product's name as the main heading for its section.
  puts "## #{product['name']}\n\n"

  # Display the core details of the product.
  puts "**Key:** `#{product['key']}`\n"
  puts "**License:** #{product['license']}\n" if product['license']
  puts "**Description:** #{product['description']}\n\n"

  # List all associated tags, if any.
  if product['tags'] && !product['tags'].empty?
    puts "### Tags\n"
    product['tags'].each do |tag|
      puts "- #{tag['text']} (#{tag['class']})"
    end
    puts "\n"
  end

  # List all supported platforms.
  if product['platforms'] && !product['platforms'].empty?
    puts "### Supported Platforms\n"
    puts product['platforms'].map { |p| "- `#{p}`" }.join("\n")
    puts "\n"
  end

  # List all features, converting snake_case to Title Case for readability.
  if product['features'] && !product['features'].empty?
    puts "### Features\n"
    puts product['features'].map { |f| "- #{f.gsub('_', ' ').capitalize}" }.join("\n")
    puts "\n"
  end

  # Detail the pricing structure.
  if product['pricing']
    puts "### Pricing Details\n"
    # Display minimum, least expensive, and maximum pricing tiers if they exist.
    ['minimum', 'least_expensive_paid', 'maximum'].each do |tier|
        if product['pricing'][tier]
            puts "**#{tier.gsub('_', ' ').capitalize} Price:**"
            price = product['pricing'][tier]
            puts "- **Cost:** #{price['cost']} #{price['unit']} / #{price['period']}"
            puts "- **Vendor:** #{price['vendor']}" if price['vendor']
            puts "- **Description:** #{price['description']}" if price['description']
        end
    end
    puts "\n"
  end

  # Detail all available hosting options.
  if product['hosting_options'] && !product['hosting_options'].empty?
    puts "### Hosting Options\n"
    product['hosting_options'].each do |option|
      puts "**- Name:** #{option['name']}"
      puts "  - **Class:** #{option['class']}" if option['class']
      puts "  - **Link:** #{option['link']}" if option['link']
      if option['price']
        price = option['price']
        puts "  - **Price:** #{price['cost']} #{price['unit']} per #{price['period']}"
      end
      puts "  - **Description:** #{option['description']}" if option['description']
      if option['buttons']
          option['buttons'].each do |button|
              puts "  - **Button:** #{button['text']} -> #{button['link']}"
          end
      end
      if option['coupon_code']
          puts "  - **Coupon Code:** #{option['coupon_code']}"
      end
       if option['coupon_value']
          coupon = option['coupon_value']
          puts "  - **Coupon Value:** #{coupon['price']} #{coupon['unit']}"
          puts "  - **Coupon Terms:** #{coupon['terms']}" if coupon['terms']
      end
      puts "" # Add a blank line for better spacing between options.
    end
    puts "\n"
  end
  # Separate each product with a horizontal rule for clarity.
  puts "\n---\n"
end

puts "Report generation complete."
