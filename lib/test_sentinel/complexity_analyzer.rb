# frozen_string_literal: true

require 'English'
module TestSentinel
  class ComplexityAnalyzer
    def self.analyze
      new.analyze
    end

    def analyze
      rubocop_output = run_rubocop
      parse_rubocop_output(rubocop_output)
    rescue StandardError => e
      raise Error, "Failed to analyze complexity: #{e.message}"
    end

    private

    def run_rubocop
      # Check for both app/ and lib/ directories
      directories = []
      directories << 'app/' if Dir.exist?('app/')
      directories << 'lib/' if Dir.exist?('lib/')

      return '' if directories.empty?

      command = "bundle exec rubocop --format json --only Metrics/CyclomaticComplexity #{directories.join(' ')}"
      result = `#{command} 2>/dev/null`

      if $CHILD_STATUS.exitstatus == 127
        # If bundler is not available, try without bundle exec
        command = "rubocop --format json --only Metrics/CyclomaticComplexity #{directories.join(' ')}"
        result = `#{command} 2>/dev/null`
      end

      result
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
        if file_path.include?('/app/')
          relative_path = file_path.split('/app/').last
          relative_path = "app/#{relative_path}" if relative_path
        elsif file_path.include?('/lib/')
          relative_path = file_path.split('/lib/').last
          relative_path = "lib/#{relative_path}" if relative_path
        else
          relative_path = file_path
        end

        next unless relative_path && (relative_path.start_with?('app/') || relative_path.start_with?('lib/'))

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
