# frozen_string_literal: true

module TestSentinel
  class Config
    attr_reader :score_weights, :directory_weights, :exclude_patterns, :git_history_days

    def initialize(data = {})
      @score_weights = data['score_weights'] || default_score_weights
      @directory_weights = data['directory_weights'] || default_directory_weights
      @exclude_patterns = data['exclude'] || default_exclude_patterns
      @git_history_days = data['git_history_days'] || 90
    end

    def self.load(file_path)
      return new unless File.exist?(file_path)

      data = YAML.load_file(file_path)
      new(data)
    rescue StandardError => e
      raise Error, "Failed to load config file: #{e.message}"
    end

    def directory_weight_for(file_path)
      @directory_weights.each do |entry|
        return entry['weight'] if file_path.start_with?(entry['path'])
      end
      1.0
    end

    def excluded?(file_path)
      @exclude_patterns.any? { |pattern| File.fnmatch(pattern, file_path) }
    end

    private

    def default_score_weights
      {
        'coverage' => 1.5,
        'complexity' => 1.0,
        'git_history' => 0.8,
        'directory' => 1.2
      }
    end

    def default_directory_weights
      [
        { 'path' => 'app/models/', 'weight' => 1.5 },
        { 'path' => 'app/services/', 'weight' => 1.5 },
        { 'path' => 'app/jobs/', 'weight' => 1.2 },
        { 'path' => 'app/controllers/', 'weight' => 1.0 }
      ]
    end

    def default_exclude_patterns
      [
        'app/channels/**/*',
        'app/helpers/**/*',
        'config/**/*',
        'db/**/*'
      ]
    end
  end
end
