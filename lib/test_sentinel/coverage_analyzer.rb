# frozen_string_literal: true

module TestSentinel
  class CoverageAnalyzer
    RESULTSET_PATH = 'coverage/.resultset.json'

    def self.analyze
      new.analyze
    end

    def analyze
      return {} unless File.exist?(RESULTSET_PATH)

      data = JSON.parse(File.read(RESULTSET_PATH))
      resultset = data.values.first

      return {} unless resultset && resultset['coverage']

      parse_coverage_data(resultset['coverage'])
    rescue JSON::ParserError => e
      raise Error, "Failed to parse coverage data: #{e.message}"
    end

    private

    def parse_coverage_data(coverage_data)
      results = {}

      coverage_data.each do |file_path, line_coverage|
        # Check if file path contains app/ or lib/ directories
        next unless file_path.include?('app/') || file_path.include?('lib/')
        next if line_coverage.nil?

        line_data = line_coverage.is_a?(Hash) ? line_coverage['lines'] : line_coverage
        next if line_data.nil?

        covered_lines = line_data.count { |hits| hits&.positive? }
        total_lines = line_data.count { |hits| !hits.nil? }

        next if total_lines.zero?

        coverage_rate = covered_lines.to_f / total_lines

        # Use relative path for consistency
        if file_path.include?('/app/')
          relative_path = file_path.split('/app/').last
          relative_path = "app/#{relative_path}" if relative_path
        elsif file_path.include?('/lib/')
          relative_path = file_path.split('/lib/').last
          relative_path = "lib/#{relative_path}" if relative_path
        elsif file_path.include?('/packs/')
          relative_path = file_path.split('/packs/').last
          relative_path = "packs/#{relative_path}" if relative_path
        else
          relative_path = file_path
        end

        results[relative_path] = {
          coverage_rate: coverage_rate,
          covered_lines: covered_lines,
          total_lines: total_lines,
          line_coverage: line_data
        }
      end

      results
    end
  end
end
