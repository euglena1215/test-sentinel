# frozen_string_literal: true

require_relative 'config_helper'

module CodeQualia
  class ScoreCalculator
    def initialize(config)
      @config = config
    end

    def calculate(coverage_data:, complexity_data:, git_data:)
      results = []

      # Get target patterns from configuration using ConfigHelper
      target_patterns = ConfigHelper.get_target_patterns

      # Collect files from configured patterns and data sources
      config_files = []
      target_patterns.each do |pattern|
        config_files.concat(Dir.glob(pattern))
      end

      all_files = (
        config_files +
        coverage_data.keys +
        complexity_data.keys +
        git_data.keys
      ).uniq

      all_files.each do |file_path|
        next if @config.excluded?(file_path)

        file_methods = extract_methods_for_file(file_path, coverage_data, complexity_data, git_data)
        results.concat(file_methods)
      end

      results.sort_by { |method| -method[:score] }
    end

    private

    def extract_methods_for_file(file_path, coverage_data, complexity_data, git_data)
      methods = []

      # Get complexity data for this file
      complexity_methods = complexity_data[file_path] || []

      # If no complexity data, try to extract methods from file
      complexity_methods = extract_methods_from_file(file_path) if complexity_methods.empty?

      complexity_methods.each do |method_data|
        method_info = {
          file_path: file_path,
          method_name: method_data[:method_name],
          line_number: method_data[:line_number],
          score: calculate_method_score(file_path, method_data, coverage_data, git_data),
          details: calculate_method_details(file_path, method_data, coverage_data, git_data)
        }

        methods << method_info
      end

      methods
    end

    def extract_methods_from_file(file_path)
      return [] unless File.exist?(file_path)

      methods = []
      File.readlines(file_path).each_with_index do |line, index|
        next unless line.strip.match?(/^\s*def\s+(\w+)/)

        method_name = line.strip.match(/^\s*def\s+(\w+)/)[1]
        methods << {
          method_name: method_name,
          line_number: index + 1,
          complexity: 1 # Default complexity
        }
      end

      methods
    end

    def calculate_method_score(file_path, method_data, coverage_data, git_data)
      quality_score = calculate_quality_score(file_path, method_data, coverage_data)
      importance_score = calculate_importance_score(file_path, git_data)
      
      final_score = quality_score * importance_score
      final_score.round(2)
    end

    def calculate_quality_score(file_path, method_data, coverage_data)
      score = 0.0

      if @config.quality_weights['test_coverage'] > 0
        coverage_factor = calculate_coverage_factor(file_path, method_data, coverage_data)
        score += @config.quality_weights['test_coverage'] * coverage_factor
      end

      if @config.quality_weights['cyclomatic_complexity'] > 0
        complexity_factor = method_data[:complexity] || 1
        score += @config.quality_weights['cyclomatic_complexity'] * complexity_factor
      end

      score
    end

    def calculate_importance_score(file_path, git_data)
      score = 0.0

      if @config.importance_weights['change_frequency'] > 0
        git_factor = git_data[file_path] || 0
        score += @config.importance_weights['change_frequency'] * git_factor
      end

      if @config.importance_weights['architectural_importance'] > 0
        architectural_factor = @config.architectural_weight_for(file_path)
        score += @config.importance_weights['architectural_importance'] * architectural_factor
      end

      score
    end

    def calculate_coverage_factor(file_path, _method_data, coverage_data)
      file_coverage = coverage_data[file_path]
      return 1.0 unless file_coverage # No coverage data means 0% coverage

      # For simplicity, use file-level coverage as method-level coverage
      # In a more sophisticated implementation, we would calculate method-level coverage
      1.0 - file_coverage[:coverage_rate]
    end

    def calculate_method_details(file_path, method_data, coverage_data, git_data)
      file_coverage = coverage_data[file_path]

      {
        coverage: file_coverage ? file_coverage[:coverage_rate] : 0.0,
        complexity: method_data[:complexity] || 1,
        git_commits: git_data[file_path] || 0
      }
    end
  end
end
