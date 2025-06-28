# frozen_string_literal: true

require 'set'
require_relative 'pattern_expander'

module TestSentinel
  class BaseAnalyzer
    protected

    def load_config
      config_file = 'sentinel.yml'
      if File.exist?(config_file)
        Config.load(config_file)
      else
        Config.new
      end
    end

    def get_target_patterns(config)
      patterns = config.directory_weights.map { |entry| entry['path'] }

      # Expand brace patterns and convert to file patterns if they're directory patterns
      expanded_patterns = []
      patterns.each do |pattern|
        if pattern.include?('{') && pattern.include?('}')
          expanded = PatternExpander.expand_brace_patterns(pattern)
          expanded_patterns.concat(expanded)
        else
          expanded_patterns << pattern
        end
      end

      # Convert directory patterns to file patterns
      expanded_patterns.map do |pattern|
        if pattern.end_with?('/')
          "#{pattern}**/*.rb"
        elsif pattern.end_with?('/**/*')
          "#{pattern}.rb"
        elsif !pattern.include?('*')
          # Assume it's a directory
          "#{pattern}/**/*.rb"
        else
          pattern
        end
      end
    end

    def should_include_file?(file_path, target_patterns)
      return false unless file_path.end_with?('.rb')

      target_patterns.any? do |pattern|
        File.fnmatch(pattern, file_path, File::FNM_PATHNAME)
      end
    end

    def normalize_file_path(file_path, config = nil)
      config ||= load_config

      # Try to find a matching base directory from the configuration
      base_directories = extract_base_directories_from_config(config)

      # Check each base directory to see if the file path contains it
      base_directories.each do |base_dir|
        dir_pattern = "/#{base_dir}"
        next unless file_path.include?(dir_pattern)

        relative_path = file_path.split(dir_pattern).last
        relative_path = "#{base_dir}#{relative_path}" if relative_path
        return relative_path
      end

      # If no base directory matches, check if it's already a relative path
      base_directories.each do |base_dir|
        return file_path if file_path.start_with?("#{base_dir}/")
      end

      # If it doesn't match any configured patterns, return the file path as-is
      # This allows for flexible configuration beyond traditional Rails structure
      file_path
    end

    private

    def extract_base_directories_from_config(config)
      directories = Set.new

      config.directory_weights.each do |entry|
        path = entry['path']

        # Extract base directory from various pattern types
        if path.include?('**')
          # Handle patterns like 'src/main/**/*.rb' -> 'src/main'
          base_dir = path.split('**').first.chomp('/')
          directories.add(base_dir) if base_dir && !base_dir.empty?
        elsif path.include?('*')
          if path.include?('{') && path.include?('}')
            # Handle brace patterns like '{src,lib}/**/*.rb'
            expanded_paths = PatternExpander.expand_brace_patterns(path)
            expanded_paths.each do |expanded|
              base_dir = expanded.split('*').first.chomp('/')
              directories.add(base_dir) if base_dir && !base_dir.empty?
            end
          else
            # Handle patterns like 'src/*.rb' -> 'src'
            base_dir = path.split('*').first.chomp('/')
            directories.add(base_dir) if base_dir && !base_dir.empty?
          end
        elsif path.end_with?('.rb')
          # Handle direct file paths
          dir = File.dirname(path)
          directories.add(dir) unless dir == '.'
        else
          # Handle directory paths
          directories.add(path.chomp('/'))
        end
      end

      directories.to_a.sort_by(&:length).reverse # Longer paths first for better matching
    end
  end
end
