# frozen_string_literal: true

require_relative 'pattern_expander'

module CodeQualia
  class Config
    attr_reader :quality_weights, :importance_weights, :architectural_weights, :exclude_patterns, :git_history_days

    def initialize(data = {})
      @quality_weights = data['quality_weights'] || default_quality_weights
      @importance_weights = data['importance_weights'] || default_importance_weights
      @architectural_weights = expand_architectural_weights(data['architectural_weights'] || default_architectural_weights)
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

    def architectural_weight_for(file_path)
      @architectural_weights.each do |entry|
        return entry['weight'] if File.fnmatch(entry['path'], file_path, File::FNM_PATHNAME)
      end
      1.0
    end

    def excluded?(file_path)
      @exclude_patterns.any? { |pattern| File.fnmatch(pattern, file_path, File::FNM_PATHNAME) }
    end

    private

    def default_quality_weights
      {
        'test_coverage' => 1.5,
        'cyclomatic_complexity' => 1.0
      }
    end

    def default_importance_weights
      {
        'change_frequency' => 0.8,
        'architectural_importance' => 1.2
      }
    end

    def default_architectural_weights
      [
        { 'path' => '**/*.rb', 'weight' => 1.0 }
      ]
    end

    def default_exclude_patterns
      [
        'config/**/*',
        'db/**/*'
      ]
    end

    def expand_architectural_weights(weights)
      expanded_weights = []
      weights.each do |entry|
        path = entry['path']
        weight = entry['weight']
        if path.include?('{') && path.include?('}')
          expanded_paths = PatternExpander.expand_brace_patterns(path)
          expanded_paths.each do |expanded_path|
            expanded_weights << { 'path' => expanded_path, 'weight' => weight }
          end
        else
          expanded_weights << entry
        end
      end
      expanded_weights
    end
  end
end
