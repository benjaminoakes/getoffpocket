#!/usr/bin/env ruby

require 'yaml'

# --- Configuration ---
# The path to your products data file.
PRODUCTS_FILE = '_data/products.yml'

# The list of product names you provided to check against.
PROVIDED_PRODUCTS = [
  "Instapaper", "Pocket", "Raindrop.io", "Safari Reading List", "EmailThis",
  "Matter", "Microsoft OneNote", "Omnivore", "Readwise Reader", "Reeder",
  "Goodlinks", "Wallabag", "Linkding", "Readeck", "LinkWarden", "Diigo",
  "Linkora", "Evernote", "PaperSpan", "Readability", "Amazon Kindle",
  "BitRead", "Bublup", "MarkMark"
].freeze

# --- Main Script Logic ---
def main
  unless File.exist?(PRODUCTS_FILE)
    puts "Error: Products file not found at '#{PRODUCTS_FILE}'"
    return
  end

  # Load the list of products from the YAML file.
  products_from_yaml = YAML.load_file(PRODUCTS_FILE)
  product_names_from_yaml = products_from_yaml.map { |p| p['name'] }

  puts "--- Checking for Differences ---"

  # Find products in the YAML file that are NOT in your provided list.
  missing_from_your_list = product_names_from_yaml - PROVIDED_PRODUCTS
  if missing_from_your_list.any?
    puts "\nProducts found in '#{PRODUCTS_FILE}' but missing from your list:"
    missing_from_your_list.each { |name| puts "  - #{name}" }
  else
    puts "\nAll products from '#{PRODUCTS_FILE}' are present in your list."
  end

  # Find products in your provided list that are NOT in the YAML file.
  missing_from_yaml_file = PROVIDED_PRODUCTS - product_names_from_yaml
  if missing_from_yaml_file.any?
    puts "\nProducts found in your list but missing from '#{PRODUCTS_FILE}':"
    missing_from_yaml_file.each { |name| puts "  - #{name}" }
  else
    puts "\nAll products from your list are present in '#{PRODUCTS_FILE}'."
  end

  puts "\n--- Check complete. ---"
end

# --- Script Execution ---
if __FILE__ == $0
  main
end
