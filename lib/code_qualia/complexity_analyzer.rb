# frozen_string_literal: true

require 'English'
require 'json'
require 'set'
require_relative 'config_helper'
require_relative 'logger'

module CodeQualia
  class ComplexityAnalyzer
    def self.analyze
      new.analyze
    end

    def analyze
      Logger.log("Starting complexity analysis")
      Logger.log("Running RuboCop command for complexity analysis")
      
      rubocop_output = run_rubocop
      parse_rubocop_output(rubocop_output)
    rescue StandardError => e
      Logger.log_error('Complexity analysis', e)
      raise Error, "Failed to analyze complexity: #{e.message}"
    end

    private

    def get_analysis_directories
      config = ConfigHelper.load_config
      directories = extract_directories_from_config(config)
      directories.select { |dir| Dir.exist?(dir) }
    end

    def extract_directories_from_config(config)
      patterns = config.directory_weights.map { |entry| entry['path'] }
      directories = PatternExpander.extract_base_directories(patterns)

      # Ensure directories end with '/' and exist
      directories.map! { |dir| dir.end_with?('/') ? dir : "#{dir}/" }
      directories.select { |dir| Dir.exist?(dir) }
    end

    def run_rubocop
      directories = get_analysis_directories
      return '' if directories.empty?

      command = "bundle exec rubocop --format json --only Metrics/CyclomaticComplexity #{directories.join(' ')}"
      result = `#{command} 2>/dev/null`

      if last_exit_status == 127
        # If bundler is not available, try without bundle exec
        command = "rubocop --format json --only Metrics/CyclomaticComplexity #{directories.join(' ')}"
        result = `#{command} 2>/dev/null`
      end

      result
    end

    def last_exit_status
      $CHILD_STATUS.exitstatus
    end

    def parse_rubocop_output(output)
      return {} if output.strip.empty?

      # Try to find JSON portion of the output
      json_start = output.index('{')
      return {} unless json_start

      json_output = output[json_start..]

      data = JSON.parse(json_output)
      results = {}

      data['files'].each do |file_data|
        file_path = file_data['path']

        # Use relative path for consistency
        relative_path = ConfigHelper.normalize_file_path(file_path)

        next if relative_path.nil? || relative_path.empty?

        file_data['offenses'].each do |offense|
          next unless offense['cop_name'] == 'Metrics/CyclomaticComplexity'

          method_info = extract_method_info(offense['message'])
          next unless method_info

          results[relative_path] ||= []
          results[relative_path] << {
            method_name: method_info[:method_name],
            line_number: offense['location']['start_line'],
            complexity: method_info[:complexity]
          }
        end
      end

      results
    rescue JSON::ParserError
      {}
    end

    def extract_method_info(message)
      # Extract complexity value and method name from RuboCop message
      # Example: "Cyclomatic complexity for `calculate_fee` is too high. [12/6]"
      match = message.match(%r{Cyclomatic complexity for `([^`]+)` is too high\. \[(\d+)/\d+\]})
      return nil unless match

      {
        method_name: match[1],
        complexity: match[2].to_i
      }
    end
  end
end
