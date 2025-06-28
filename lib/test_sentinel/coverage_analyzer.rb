# frozen_string_literal: true

require_relative 'base_analyzer'

module TestSentinel
  class CoverageAnalyzer < BaseAnalyzer
    RESULTSET_PATH = 'coverage/.resultset.json'

    def self.analyze
      new.analyze
    end

    def analyze
      return {} unless File.exist?(RESULTSET_PATH)

      data = JSON.parse(File.read(RESULTSET_PATH))
      resultset = data.values.first

      return {} unless resultset && resultset['coverage']

      config = load_config
      parse_coverage_data(resultset['coverage'], config)
    rescue JSON::ParserError => e
      raise Error, "Failed to parse coverage data: #{e.message}"
    end

    private

    def parse_coverage_data(coverage_data, config = nil)
      # For backward compatibility with tests
      config = load_config if config.nil?

      results = {}
      target_patterns = get_target_patterns(config)

      coverage_data.each do |file_path, line_coverage|
        next unless should_include_file_for_coverage?(file_path, target_patterns)
        next if line_coverage.nil?

        line_data = line_coverage.is_a?(Hash) ? line_coverage['lines'] : line_coverage
        next if line_data.nil?

        covered_lines = line_data.count { |hits| hits&.positive? }
        total_lines = line_data.count { |hits| !hits.nil? }

        next if total_lines.zero?

        coverage_rate = covered_lines.to_f / total_lines
        relative_path = normalize_file_path(file_path)

        next if relative_path.nil?

        results[relative_path] = {
          coverage_rate: coverage_rate,
          covered_lines: covered_lines,
          total_lines: total_lines,
          line_coverage: line_data
        }
      end

      results
    end

    def should_include_file_for_coverage?(file_path, target_patterns)
      return false unless file_path.end_with?('.rb')

      target_patterns.any? do |pattern|
        File.fnmatch(pattern, file_path, File::FNM_PATHNAME) ||
          File.fnmatch("**/#{pattern}", file_path, File::FNM_PATHNAME)
      end
    end
  end
end
