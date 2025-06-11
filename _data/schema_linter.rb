require 'yaml'
require 'json'

# Defines a class for linting and fixing a YAML file against a schema.
class SchemaLinter
  # Initializes the SchemaLinter with a schema file.
  #
  # @param schema_file [String] The path to the schema file.
  def initialize(schema_file)
    unless File.exist?(schema_file)
      puts "Error: Schema file not found at '#{schema_file}'"
      exit
    end
    @schema = YAML.load_file(schema_file)
  end

  # Lints and fixes a data file against the schema.
  #
  # @param data_file [String] The path to the data file.
  def lint_and_fix(data_file)
    unless File.exist?(data_file)
      puts "Error: Data file not found at '#{data_file}'"
      exit
    end
    data = YAML.load_file(data_file)
    fixed_data = fix_node(data, @schema)

    # Write the fixed data back to the file
    File.open(data_file, 'w') do |file|
      file.write(YAML.dump(fixed_data))
    end
  end

  private

  # Recursively fixes a data node against a schema node.
  #
  # @param data [Object] The data node to fix.
  # @param schema [Object] The schema node to validate against.
  # @param path [String] The current path for error reporting.
  # @return [Object] The fixed data node.
  def fix_node(data, schema, path = "")
    if schema.is_a?(Hash) && data.is_a?(Hash)
      schema.each do |key, schema_value|
        new_path = path.empty? ? key : "#{path}.#{key}"
        if data.key?(key)
          data[key] = fix_node(data[key], schema_value, new_path)
        end
      end
    elsif schema.is_a?(Array) && data.is_a?(Array)
      data.each_with_index do |item, index|
        data[index] = fix_node(item, schema.first, "#{path}[#{index}]")
      end
    elsif data.class != schema.class
      # Attempt to fix type mismatches
      if schema.is_a?(Float) && data.is_a?(Integer)
        puts "Fixing type mismatch at #{path}: converting Integer to Float."
        return data.to_f
      end
    end
    data
  end
end

# --- Script Execution ---

# Check if two filenames were provided as command-line arguments.
unless ARGV.length == 2
  puts "Usage: ruby #{$0} <schema_file.yml> <data_file_to_fix.yml>"
  exit
end

# The schema and data files are taken from the command-line arguments.
schema_file = ARGV[0]
file_to_fix = ARGV[1]

# Create a linter with the provided schema file.
linter = SchemaLinter.new(schema_file)

# Lint and fix the provided data file.
puts "Linting and fixing '#{file_to_fix}' against schema '#{schema_file}'..."
linter.lint_and_fix(file_to_fix)
puts "Linting complete. File has been updated."
