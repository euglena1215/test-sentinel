# frozen_string_literal: true

require 'json'
require 'yaml'
require_relative 'code_qualia/coverage_analyzer'
require_relative 'code_qualia/complexity_analyzer'
require_relative 'code_qualia/git_analyzer'
require_relative 'code_qualia/score_calculator'
require_relative 'code_qualia/config'
require_relative 'code_qualia/config_installer'
require_relative 'code_qualia/cli'
require_relative 'code_qualia/logger'

module CodeQualia
  class Error < StandardError; end
  
  DEFAULT_CONFIG_FILE = 'qualia.yml'

  class << self
    def analyze(config_path = './qualia.yml', verbose: false)
      Logger.verbose = verbose
      Logger.log_step('Analysis')

      config = Config.load(config_path)
      Logger.log('Configuration loaded')

      coverage_data = if config.quality_weights['test_coverage'] > 0
                        Logger.log_step('Coverage analysis')
                        result = CoverageAnalyzer.analyze
                        Logger.log_result('Coverage analysis', result.size)
                        result
                      else
                        Logger.log_skip('Coverage analysis', 'weight is 0')
                        {}
                      end

      complexity_data = if config.quality_weights['cyclomatic_complexity'] > 0
                          Logger.log_step('Complexity analysis')
                          result = ComplexityAnalyzer.analyze
                          Logger.log_result('Complexity analysis', result.values.sum(&:size))
                          result
                        else
                          Logger.log_skip('Complexity analysis', 'weight is 0')
                          {}
                        end

      git_data = if config.importance_weights['change_frequency'] > 0
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
