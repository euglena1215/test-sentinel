# frozen_string_literal: true

module TestSentinel
  class Config
    attr_reader :score_weights, :directory_weights, :exclude_patterns, :git_history_days

    def initialize(data = {})
      @score_weights = data['score_weights'] || default_score_weights
      @directory_weights = expand_directory_weights(data['directory_weights'] || default_directory_weights)
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
        return entry['weight'] if File.fnmatch(entry['path'], file_path, File::FNM_PATHNAME)
      end
      1.0
    end

    def excluded?(file_path)
      @exclude_patterns.any? { |pattern| File.fnmatch(pattern, file_path, File::FNM_PATHNAME) }
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
        { 'path' => 'app/models/**/*.rb', 'weight' => 1.5 },
        { 'path' => 'app/services/**/*.rb', 'weight' => 1.5 },
        { 'path' => 'app/jobs/**/*.rb', 'weight' => 1.2 },
        { 'path' => 'app/controllers/**/*.rb', 'weight' => 1.0 }
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

    def expand_directory_weights(weights)
      expanded_weights = []
      weights.each do |entry|
        path = entry['path']
        weight = entry['weight']
        if path.include?('{') && path.include?('}')
          expanded_paths = expand_brace_patterns(path)
          expanded_paths.each do |expanded_path|
            expanded_weights << { 'path' => expanded_path, 'weight' => weight }
          end
        else
          expanded_weights << entry
        end
      end
      expanded_weights
    end

    def expand_brace_patterns(pattern)
      parts = pattern.split('{', 2)
      prefix = parts[0]
      suffix_and_rest = parts[1].split('}', 2)
      options = suffix_and_rest[0].split(',')
      suffix = suffix_and_rest[1]

      expanded = []
      options.each do |option|
        expanded_pattern = "#{prefix}#{option}#{suffix}"
        if expanded_pattern.include?('{') && expanded_pattern.include?('}')
          expanded.concat(expand_brace_patterns(expanded_pattern))
        else
          expanded << expanded_pattern
        end
      end
      expanded
    end
  end
end
