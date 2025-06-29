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

      start_time = Time.now
      config = Config.load(config_path)
      Logger.log('Configuration loaded')

      coverage_data = if config.score_weights['coverage'] > 0
                        Logger.log_step('Coverage analysis')
                        coverage_start = Time.now
                        result = CoverageAnalyzer.analyze
                        coverage_duration = Time.now - coverage_start
                        Logger.log_result('Coverage analysis', result.size, coverage_duration)
                        result
                      else
                        Logger.log_skip('Coverage analysis', 'weight is 0')
                        {}
                      end

      complexity_data = if config.score_weights['complexity'] > 0
                          Logger.log_step('Complexity analysis')
                          complexity_start = Time.now
                          result = ComplexityAnalyzer.analyze
                          complexity_duration = Time.now - complexity_start
                          Logger.log_result('Complexity analysis', result.values.sum(&:size), complexity_duration)
                          result
                        else
                          Logger.log_skip('Complexity analysis', 'weight is 0')
                          {}
                        end

      git_data = if config.score_weights['git_history'] > 0
                   Logger.log_step('Git history analysis')
                   git_start = Time.now
                   result = GitAnalyzer.analyze(config.git_history_days)
                   git_duration = Time.now - git_start
                   Logger.log_result('Git history analysis', result.size, git_duration)
                   result
                 else
                   Logger.log_skip('Git history analysis', 'weight is 0')
                   {}
                 end

      Logger.log_step('Score calculation')
      score_start = Time.now
      results = ScoreCalculator.new(config).calculate(
        coverage_data: coverage_data,
        complexity_data: complexity_data,
        git_data: git_data
      )
      score_duration = Time.now - score_start
      total_duration = Time.now - start_time

      Logger.log_result('Score calculation', results.size, score_duration)
      Logger.log_result('Total analysis', results.size, total_duration)

      results
    end
  end
end
