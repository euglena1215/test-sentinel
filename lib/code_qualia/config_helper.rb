# frozen_string_literal: true

require 'pathname'
require_relative 'pattern_expander'
require_relative 'config'

module CodeQualia
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

      # Normalizes a file path to a relative path from the current working directory.
      #
      # This method takes an absolute file path and converts it to a relative path
      # from the current working directory. This preserves the full directory structure
      # including any intermediate directories like 'packs/users/'.
      #
      # @param file_path [String] The file path to normalize (can be absolute or relative)
      # @return [String] Relative path from current working directory
      # @example
      #   ConfigHelper.normalize_file_path("/full/path/to/project/packs/users/app/models/user.rb")
      #   # => "packs/users/app/models/user.rb"
      #   ConfigHelper.normalize_file_path("app/models/user.rb")
      #   # => "app/models/user.rb"
      def normalize_file_path(file_path)
        # If already a relative path, return as-is
        return file_path unless Pathname.new(file_path).absolute?

        # Convert absolute path to relative path from current working directory
        current_dir = Dir.pwd
        if file_path.start_with?(current_dir)
          relative_path = file_path[(current_dir.length + 1)..-1]
          return relative_path || file_path
        end

        # If it doesn't start with current directory, return as-is
        file_path
      end

      # Loads the Code Qualia configuration from file or returns default configuration.
      #
      # This method attempts to load the configuration from the default config file
      # (qualia.yml). If the file doesn't exist, it returns a new Config instance
      # with default values.
      #
      # @return [CodeQualia::Config] Loaded configuration or default configuration
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
    end
  end
end
