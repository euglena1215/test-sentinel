# frozen_string_literal: true

require 'set'

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
          base_dir = extract_base_directory_from_pattern(expanded_pattern)
          directories.add("#{base_dir}/") if base_dir && !base_dir.empty?
        end
      end

      directories.to_a
    end

    private

    def extract_base_directory_from_pattern(pattern)
      if pattern.include?('**')
        # Handle patterns like 'app/models/**/*.rb' -> 'app'
        pattern.split('**').first.chomp('/')
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
  end
end
