# frozen_string_literal: true

require_relative 'pattern_expander'
require_relative 'config'

module TestSentinel
  class ConfigHelper
    class << self
      # Gets target file patterns from configuration and expands them to glob patterns.
      #
      # This method reads the directory_weights configuration, expands any brace patterns
      # (e.g., 'app/{models,controllers}/**/*.rb'), and converts directory patterns to
      # file patterns by appending '**/*.rb' when necessary.
      #
      # @return [Array<String>] Array of expanded glob patterns for target files
      # @example
      #   ConfigHelper.get_target_patterns
      #   # => ["app/models/**/*.rb", "app/controllers/**/*.rb", "lib/**/*.rb"]
      def get_target_patterns
        config = load_config
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

      # Checks if a file should be included based on target patterns.
      #
      # This method determines whether a given file path matches any of the provided
      # target patterns. Only Ruby files (.rb extension) are considered for inclusion.
      #
      # @param file_path [String] The file path to check
      # @param target_patterns [Array<String>] Array of glob patterns to match against
      # @return [Boolean] true if the file should be included, false otherwise
      # @example
      #   patterns = ["app/models/**/*.rb", "lib/**/*.rb"]
      #   ConfigHelper.should_include_file?("app/models/user.rb", patterns)
      #   # => true
      #   ConfigHelper.should_include_file?("app/views/index.html.erb", patterns)
      #   # => false
      def should_include_file?(file_path, target_patterns)
        return false unless file_path.end_with?('.rb')

        target_patterns.any? do |pattern|
          File.fnmatch(pattern, file_path, File::FNM_PATHNAME)
        end
      end

      # Normalizes a file path to a relative path based on configured base directories.
      #
      # This method takes an absolute or mixed file path and converts it to a normalized
      # relative path starting from configured base directories (e.g., 'app/', 'lib/').
      # This ensures consistent file path representation across different execution contexts.
      #
      # @param file_path [String] The file path to normalize (can be absolute or relative)
      # @return [String] Normalized relative path starting from base directory
      # @example
      #   ConfigHelper.normalize_file_path("/full/path/to/project/app/models/user.rb")
      #   # => "app/models/user.rb"
      #   ConfigHelper.normalize_file_path("lib/my_gem/version.rb")
      #   # => "lib/my_gem/version.rb"
      def normalize_file_path(file_path)
        # Load configuration and try to find a matching base directory
        config = load_config
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

      # Loads the Test Sentinel configuration from file or returns default configuration.
      #
      # This method attempts to load the configuration from the default config file
      # (sentinel.yml). If the file doesn't exist, it returns a new Config instance
      # with default values.
      #
      # @return [TestSentinel::Config] Loaded configuration or default configuration
      # @example
      #   config = ConfigHelper.load_config
      #   puts config.directory_weights
      #   # => [{"path"=>"**/*.rb", "weight"=>1.0}]
      def load_config
        if File.exist?(DEFAULT_CONFIG_FILE)
          Config.load(DEFAULT_CONFIG_FILE)
        else
          Config.new
        end
      end

      private

      def extract_base_directories_from_config(config)
        # Extract patterns from config
        patterns = config.directory_weights.map { |entry| entry['path'] }

        # Use PatternExpander to extract base directories
        directories = PatternExpander.extract_base_directories(patterns)

        # Remove trailing slashes and sort by length (longer paths first for better matching)
        directories.map { |dir| dir.chomp('/') }
                   .reject(&:empty?)
                   .uniq
                   .sort_by(&:length)
                   .reverse
      end
    end
  end
end
