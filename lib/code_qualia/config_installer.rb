# frozen_string_literal: true

require_relative 'config_helper'

module CodeQualia
  class ConfigInstaller
    def initialize(directory)
      @directory = File.expand_path(directory)
    end

    def install
      if config_exists?
        puts "⚠️  Configuration file '#{DEFAULT_CONFIG_FILE}' already exists."
        puts '   Use --force to overwrite or remove the existing file.'
        return
      end

      project_type = detect_project_type
      puts "🔍 Detected project type: #{project_type}"

      config_content = generate_config(project_type)
      write_config(config_content)

      puts "✅ Configuration file '#{DEFAULT_CONFIG_FILE}' created successfully!"
      puts '   You can now run: code-qualia generate'
    end

    private

    def config_exists?
      File.exist?(config_path)
    end

    def config_path
      File.join(@directory, DEFAULT_CONFIG_FILE)
    end

    def detect_project_type
      if rails_project?
        'Rails application'
      elsif gem_project?
        'Ruby gem'
      else
        'Ruby project'
      end
    end

    def rails_project?
      # Check for Rails indicators
      gemfile_path = File.join(@directory, 'Gemfile')
      return false unless File.exist?(gemfile_path)

      gemfile_content = File.read(gemfile_path)
      rails_in_gemfile = gemfile_content.match?(/gem\s+['"]rails['"]/)
      app_directory_exists = Dir.exist?(File.join(@directory, 'app'))

      rails_in_gemfile && app_directory_exists
    end

    def gem_project?
      # Check for gem indicators
      gemspec_files = Dir.glob(File.join(@directory, '*.gemspec'))
      lib_directory_exists = Dir.exist?(File.join(@directory, 'lib'))

      !gemspec_files.empty? && lib_directory_exists
    end

    def generate_config(project_type)
      case project_type
      when 'Rails application'
        rails_config
      when 'Ruby gem'
        gem_config
      else
        default_config
      end
    end

    def rails_config
      <<~YAML
        score_weights:
          coverage: 1.5
          complexity: 1.0
          git_history: 0.8
          directory: 1.2

        directory_weights:
          - path: 'app/models/**/*.rb'
            weight: 2.0
          - path: 'app/controllers/**/*.rb'
            weight: 1.5
          - path: 'app/services/**/*.rb'
            weight: 1.8
          - path: 'app/**/*.rb'
            weight: 1.0
          - path: 'lib/**/*.rb'
            weight: 1.0

        exclude:
          - 'app/channels/**/*'
          - 'app/helpers/**/*'
          - 'app/views/**/*'
          - 'app/assets/**/*'
          - 'config/**/*'
          - 'db/**/*'
          - 'spec/**/*'
          - 'test/**/*'

        git_history_days: 90
      YAML
    end

    def gem_config
      <<~YAML
        score_weights:
          coverage: 1.5
          complexity: 1.0
          git_history: 0.8
          directory: 1.2

        directory_weights:
          - path: 'lib/**/*.rb'
            weight: 1.0
          - path: 'bin/**/*'
            weight: 1.3

        exclude:
          - 'spec/**/*'
          - 'test/**/*'
          - 'Gemfile*'

        git_history_days: 90
      YAML
    end

    def default_config
      <<~YAML
        score_weights:
          coverage: 1.5
          complexity: 1.0
          git_history: 0.8
          directory: 1.2

        directory_weights:
          - path: 'app/**/*.rb'
            weight: 1.0
          - path: 'lib/**/*.rb'
            weight: 1.0

        exclude:
          - 'config/**/*'
          - 'db/**/*'
          - 'spec/**/*'
          - 'test/**/*'

        git_history_days: 90
      YAML
    end

    def write_config(content)
      File.write(config_path, content)
    end
  end
end
