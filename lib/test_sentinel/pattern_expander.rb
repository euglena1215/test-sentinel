# frozen_string_literal: true

require 'set'
require 'pathname'

module TestSentinel
  class PatternExpander
    def self.expand_brace_patterns(pattern)
      new.expand_brace_patterns(pattern)
    end

    def expand_brace_patterns(pattern)
      parts = pattern.split('{', 2)
      return [pattern] unless parts.length == 2

      prefix = parts[0]
      suffix_and_rest = parts[1].split('}', 2)
      return [pattern] unless suffix_and_rest.length == 2

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

    def self.extract_base_directories(patterns)
      new.extract_base_directories(patterns)
    end

    def extract_base_directories(patterns)
      directories = Set.new

      Array(patterns).each do |pattern|
        expanded_patterns = if pattern.include?('{') && pattern.include?('}')
                              expand_brace_patterns(pattern)
                            else
                              [pattern]
                            end

        expanded_patterns.each do |expanded_pattern|
          base_dirs = extract_base_directory_from_pattern(expanded_pattern)

          # Handle both single directory (string) and multiple directories (array)
          base_dirs = Array(base_dirs)
          base_dirs.each do |base_dir|
            directories.add("#{base_dir}/") if base_dir && !base_dir.empty?
          end
        end
      end

      directories.to_a
    end

    private

    def extract_base_directory_from_pattern(pattern)
      if pattern.include?('**')
        base_path = pattern.split('**').first.chomp('/')

        # Handle special case of '**/*.rb' - detect common Ruby project directories
        return detect_ruby_project_directories if base_path.empty? && pattern == '**/*.rb'

        base_path
      elsif pattern.include?('*')
        # Handle patterns like 'app/models/*.rb' -> 'app'
        pattern.split('*').first.chomp('/')
      elsif File.directory?(pattern)
        # Handle direct directory paths
        pattern.chomp('/')
      elsif pattern.end_with?('.rb')
        # Handle direct file paths
        dir = File.dirname(pattern)
        dir == '.' ? nil : dir
      else
        # Assume it's a directory pattern
        pattern.chomp('/')
      end
    end

    private

    def detect_ruby_project_directories
      # Use Pathname.glob to find all Ruby files, then extract their top-level directories
      ruby_files = Pathname.glob('**/*.rb')

      # Extract unique top-level directories that contain Ruby files
      ruby_files
        .map { |file| extract_top_level_directory(file) } # Get top-level directory directly from file
        .compact # Remove nils
        .uniq                             # Remove duplicates
        .map(&:to_s)                      # Convert back to strings
        .sort                             # Sort for consistency
    end

    # Extract the top-level directory from a path
    # Examples:
    #   app/models/user.rb -> app
    #   lib/my_gem/version.rb -> lib
    #   src/main.rb -> src
    #   script/console.rb -> script
    #   user.rb -> nil (root level file)
    def extract_top_level_directory(pathname)
      parts = pathname.each_filename.to_a
      return nil if parts.length < 2 # Skip root-level files (need at least dir/file.rb)

      parts.first
    end
  end
end
