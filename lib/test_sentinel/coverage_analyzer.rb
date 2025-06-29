# frozen_string_literal: true

require_relative 'config_helper'
require_relative 'logger'

module TestSentinel
  class CoverageAnalyzer
    RESULTSET_PATH = 'coverage/.resultset.json'

    def self.analyze
      new.analyze
    end

    def analyze
      Logger.log("Looking for coverage data at #{RESULTSET_PATH}")
      
      unless File.exist?(RESULTSET_PATH)
        Logger.log("Coverage file not found: #{RESULTSET_PATH}")
        return {}
      end

      Logger.log("Reading coverage data from #{RESULTSET_PATH}")
      data = JSON.parse(File.read(RESULTSET_PATH))
      resultset = data.values.first

      unless resultset && resultset['coverage']
        Logger.log("No coverage data found in resultset")
        return {}
      end

      Logger.log("Found coverage data for #{resultset['coverage'].size} files")
      parse_coverage_data(resultset['coverage'])
    rescue JSON::ParserError => e
      Logger.log_error('Coverage analysis', e)
      raise Error, "Failed to parse coverage data: #{e.message}"
    end

    private

    def parse_coverage_data(coverage_data)

      results = {}
      target_patterns = ConfigHelper.get_target_patterns

      coverage_data.each do |file_path, line_coverage|
        next unless should_include_file_for_coverage?(file_path, target_patterns)
        next if line_coverage.nil?

        line_data = line_coverage.is_a?(Hash) ? line_coverage['lines'] : line_coverage
        next if line_data.nil?

        covered_lines = line_data.count { |hits| hits&.positive? }
        total_lines = line_data.count { |hits| !hits.nil? }

        next if total_lines.zero?

        coverage_rate = covered_lines.to_f / total_lines
        relative_path = ConfigHelper.normalize_file_path(file_path)

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
