# frozen_string_literal: true

require 'optparse'
require 'json'
require_relative '../code_qualia'

module CodeQualia
  class CLI
    def initialize(argv)
      @argv = argv
      @options = {
        top_n: 3,
        config: './qualia.yml',
        directory: Dir.pwd,
        format: 'human',
        verbose: false
      }
    end

    def run
      parse_options

      case @command
      when 'generate'
        generate_analysis
      when 'install'
        install_config
      else
        show_help
      end
    end

    private

    def parse_options
      parser = OptionParser.new do |opts|
        opts.banner = 'Usage: code-qualia [command] [options]'
        opts.separator ''
        opts.separator 'Commands:'
        opts.separator '  generate    Analyze codebase and generate test recommendations'
        opts.separator '  install     Setup configuration file for your project'
        opts.separator ''
        opts.separator 'Options:'

        opts.on('--top-n N', Integer, 'Number of top priority methods to analyze (default: 3)') do |n|
          @options[:top_n] = n
        end

        opts.on('--config PATH', String, 'Path to configuration file (default: ./qualia.yml)') do |path|
          @options[:config] = path
        end

        opts.on('--directory DIR', String, 'Directory to analyze (default: current directory)') do |dir|
          @options[:directory] = dir
        end

        opts.on('--format FORMAT', String, 'Output format: human, json, csv, table (default: human)') do |format|
          unless %w[human json csv table].include?(format)
            puts "Error: Invalid format '#{format}'. Valid formats: human, json, csv, table"
            exit_with_code(1)
          end
          @options[:format] = format
        end

        opts.on('-v', '--verbose', 'Enable verbose logging') do
          @options[:verbose] = true
        end

        opts.on('-h', '--help', 'Show this help message') do
          puts opts
          exit_with_code(0)
        end
      end

      parser.parse!(@argv)
      @command = @argv.shift
    end

    def generate_analysis
      original_dir = Dir.pwd

      begin
        # Change to target directory for analysis
        Dir.chdir(@options[:directory])

        results = CodeQualia.analyze(@options[:config], verbose: @options[:verbose])

        if results.empty?
          case @options[:format]
          when 'json'
            puts '[]'
          when 'csv'
            puts 'file_path,method_name,line_number,score,coverage,complexity,git_commits'
          when 'table'
            puts 'No methods found that need additional testing.'
          else
            puts '✅ No methods found that need additional testing.'
          end
          return
        end

        top_results = results.take(@options[:top_n])

        case @options[:format]
        when 'json'
          output_json_format(top_results)
        when 'csv'
          output_csv_format(top_results)
        when 'table'
          output_table_format(top_results)
        else # 'human'
          output_human_format(top_results)
        end
      rescue CodeQualia::Error => e
        puts "❌ Error: #{e.message}"
        exit_with_code(1)
      rescue StandardError => e
        puts "❌ Unexpected error: #{e.message}"
        exit_with_code(1)
      ensure
        Dir.chdir(original_dir)
      end
    end

    def output_human_format(results)
      puts "📊 Top #{results.length} methods requiring test coverage:\n\n"

      results.each_with_index do |method, index|
        puts "#{index + 1}. #{method[:file_path]}:#{method[:line_number]}"
        puts "   Method: #{method[:method_name]}"
        puts "   Priority Score: #{method[:score]}"
        puts "   Coverage: #{(method[:details][:coverage] * 100).round(1)}%"
        puts "   Complexity: #{method[:details][:complexity]}"
        puts "   Git Commits: #{method[:details][:git_commits]}"
        puts ''
      end
    end

    def output_json_format(results)
      json_output = results.map do |method|
        {
          file_path: method[:file_path],
          class_name: extract_class_name(method[:file_path]),
          method_name: method[:method_name],
          line_number: method[:line_number],
          score: method[:score],
          details: method[:details]
        }
      end

      puts JSON.pretty_generate(json_output)
    end

    def output_csv_format(results)
      puts 'file_path,method_name,line_number,score,coverage,complexity,git_commits'

      results.each do |method|
        coverage_percent = (method[:details][:coverage] * 100).round(1)
        puts "#{method[:file_path]},#{method[:method_name]},#{method[:line_number]},#{method[:score]},#{coverage_percent},#{method[:details][:complexity]},#{method[:details][:git_commits]}"
      end
    end

    def output_table_format(results)
      require 'io/console'

      # Calculate column widths
      max_file = results.map { |r| r[:file_path].length }.max || 20
      max_method = [results.map { |r| r[:method_name].length }.max, 20].min

      # Header
      puts "+#{'-' * (max_file + 2)}+#{'-' * (max_method + 2)}+------+-------+----------+------------+----------+"
      printf "| %-#{max_file}s | %-#{max_method}s | Line | Score | Coverage | Complexity | Commits  |\n", 'File', 'Method'
      puts "+#{'-' * (max_file + 2)}+#{'-' * (max_method + 2)}+------+-------+----------+------------+----------+"

      # Data rows
      results.each do |method|
        file_name = method[:file_path]
        method_name = method[:method_name].length > max_method ? method[:method_name][0...max_method - 1] + '…' : method[:method_name]
        coverage_percent = (method[:details][:coverage] * 100).round(1)

        printf "| %-#{max_file}s | %-#{max_method}s | %4d | %5.2f | %7.1f%% | %10d | %8d |\n",
               file_name, method_name, method[:line_number], method[:score],
               coverage_percent, method[:details][:complexity], method[:details][:git_commits]
      end

      puts "+#{'-' * (max_file + 2)}+#{'-' * (max_method + 2)}+------+-------+----------+------------+----------+"
    end

    def extract_class_name(file_path)
      # Simple heuristic to extract class name from file path
      File.basename(file_path, '.rb').split('_').map(&:capitalize).join
    end

    def install_config
      installer = CodeQualia::ConfigInstaller.new(@options[:directory])
      installer.install
    rescue CodeQualia::Error => e
      puts "❌ Error: #{e.message}"
      exit_with_code(1)
    rescue StandardError => e
      puts "❌ Unexpected error: #{e.message}"
      exit_with_code(1)
    end

    def show_help
      puts 'code-qualia - AI-powered test coverage analysis tool'
      puts ''
      puts 'Usage: code-qualia [command] [options]'
      puts ''
      puts 'Commands:'
      puts '  generate    Analyze codebase and generate test recommendations'
      puts '  install     Setup configuration file for your project'
      puts ''
      puts "Run 'code-qualia [command] --help' for more information."
    end

    private

    def exit_with_code(code)
      exit(code)
    end
  end
end