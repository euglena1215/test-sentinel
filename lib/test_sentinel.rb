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
require_relative 'test_sentinel/logger'

module TestSentinel
  class Error < StandardError; end
  
  DEFAULT_CONFIG_FILE = 'sentinel.yml'

  class << self
    def analyze(config_path = './sentinel.yml', verbose: false)
      Logger.verbose = verbose
      Logger.log_step('Analysis')

      config = Config.load(config_path)
      Logger.log('Configuration loaded')

      coverage_data = if config.score_weights['coverage'] > 0
                        Logger.log_step('Coverage analysis')
                        result = CoverageAnalyzer.analyze
                        Logger.log_result('Coverage analysis', result.size)
                        result
                      else
                        Logger.log_skip('Coverage analysis', 'weight is 0')
                        {}
                      end

      complexity_data = if config.score_weights['complexity'] > 0
                          Logger.log_step('Complexity analysis')
                          result = ComplexityAnalyzer.analyze
                          Logger.log_result('Complexity analysis', result.values.sum(&:size))
                          result
                        else
                          Logger.log_skip('Complexity analysis', 'weight is 0')
                          {}
                        end

      git_data = if config.score_weights['git_history'] > 0
                   Logger.log_step('Git history analysis')
                   result = GitAnalyzer.analyze(config.git_history_days)
                   Logger.log_result('Git history analysis', result.size)
                   result
                 else
                   Logger.log_skip('Git history analysis', 'weight is 0')
                   {}
                 end

      Logger.log_step('Score calculation')
      results = ScoreCalculator.new(config).calculate(
        coverage_data: coverage_data,
        complexity_data: complexity_data,
        git_data: git_data
      )
      Logger.log_result('Score calculation', results.size)

      results
    end
  end
end
