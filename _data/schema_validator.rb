require 'yaml'
require 'json'

# Defines a class for validating a YAML file against a schema.
class SchemaValidator
  # Initializes the SchemaValidator with a schema file.
  #
  # @param schema_file [String] The path to the schema file.
  def initialize(schema_file)
    unless File.exist?(schema_file)
      puts "Error: Schema file not found at '#{schema_file}'"
      exit
    end
    @schema = YAML.load_file(schema_file)
  end

  # Validates a data file against the schema.
  #
  # @param data_file [String] The path to the data file.
  def validate(data_file)
    unless File.exist?(data_file)
      puts "Error: Data file not found at '#{data_file}'"
      exit
    end
    data = YAML.load_file(data_file)
    validate_node(data, @schema)
  end

  private

  # Recursively validates a data node against a schema node.
  #
  # @param data [Object] The data node to validate.
  # @param schema [Object] The schema node to validate against.
  # @param path [String] The current path for error reporting.
  def validate_node(data, schema, path = "")
    if schema.is_a?(Hash) && data.is_a?(Hash)
      schema.each do |key, schema_value|
        new_path = path.empty? ? key : "#{path}.#{key}"
        unless data.key?(key)
          # 'description' is now an optional key.
          puts "Missing key: #{new_path}" unless key == 'description'
          next
        end
        validate_node(data[key], schema_value, new_path)
      end
    elsif schema.is_a?(Array) && data.is_a?(Array)
      data.each_with_index do |item, index|
        validate_node(item, schema.first, "#{path}[#{index}]")
      end
    elsif data.class != schema.class
      puts "Type mismatch at #{path}: expected #{schema.class}, got #{data.class}"
    end
  end
end

# --- Script Execution ---

# Check if two filenames were provided as command-line arguments.
unless ARGV.length == 2
  puts "Usage: ruby #{$0} <schema_file.yml> <data_file_to_validate.yml>"
  exit
end

# The schema and data files are taken from the command-line arguments.
schema_file = ARGV[0]
file_to_validate = ARGV[1]

# Create a validator with the provided schema file.
validator = SchemaValidator.new(schema_file)

# Validate the provided data file.
puts "Validating '#{file_to_validate}' against schema '#{schema_file}'..."
validator.validate(file_to_validate)
puts "Validation complete."
