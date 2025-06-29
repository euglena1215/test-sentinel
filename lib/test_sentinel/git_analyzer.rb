# frozen_string_literal: true

require 'date'
require_relative 'config_helper'

module TestSentinel
  class GitAnalyzer
    def self.analyze(days = 90)
      new(days).analyze
    end

    def initialize(days = 90)
      @days = days
    end

    def analyze
      return {} unless git_repository?

      config = ConfigHelper.load_config
      git_log_output = run_git_log
      parse_git_log(git_log_output, config)
    rescue StandardError => e
      raise Error, "Failed to analyze git history: #{e.message}"
    end

    private

    def git_repository?
      system('git rev-parse --git-dir > /dev/null 2>&1')
    end

    def run_git_log
      since_date = (Date.today - @days).strftime('%Y-%m-%d')
      command = "git log --since=#{since_date} --name-only --pretty=format:"
      `#{command} 2>/dev/null`
    end

    def parse_git_log(output, config = nil)
      # For backward compatibility with tests
      config = ConfigHelper.load_config if config.nil?

      results = {}
      target_patterns = ConfigHelper.get_target_patterns

      output.split("\n").each do |line|
        line = line.strip
        next if line.empty?
        next unless ConfigHelper.should_include_file?(line, target_patterns)

        results[line] ||= 0
        results[line] += 1
      end

      results
    end
  end
end
