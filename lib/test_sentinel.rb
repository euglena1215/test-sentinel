# frozen_string_literal: true

require 'json'
require 'yaml'
require_relative 'test_sentinel/coverage_analyzer'
require_relative 'test_sentinel/complexity_analyzer'
require_relative 'test_sentinel/git_analyzer'
require_relative 'test_sentinel/score_calculator'
require_relative 'test_sentinel/config'
require_relative 'test_sentinel/config_installer'
require_relative 'test_sentinel/cli'

module TestSentinel
  class Error < StandardError; end
  
  DEFAULT_CONFIG_FILE = 'sentinel.yml'

  class << self
    def analyze(config_path = './sentinel.yml')
      config = Config.load(config_path)

      coverage_data = CoverageAnalyzer.analyze
      complexity_data = ComplexityAnalyzer.analyze
      git_data = GitAnalyzer.analyze(config.git_history_days)

      ScoreCalculator.new(config).calculate(
        coverage_data: coverage_data,
        complexity_data: complexity_data,
        git_data: git_data
      )
    end
  end
end
