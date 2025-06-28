# frozen_string_literal: true

module TestSentinel
  class ScenarioGenerator
    def self.generate_for_method(file_path, method_name, line_number)
      new(file_path, method_name, line_number).generate
    end

    def initialize(file_path, method_name, line_number)
      @file_path = file_path
      @method_name = method_name
      @line_number = line_number
    end

    def generate
      return [] unless File.exist?(@file_path)

      method_code = extract_method_code
      return [] if method_code.empty?

      analyze_method_code(method_code)
    end

    private

    def extract_method_code
      lines = File.readlines(@file_path)
      method_lines = []

      start_index = @line_number - 1
      current_index = start_index
      indent_level = nil

      while current_index < lines.length
        line = lines[current_index]

        if indent_level.nil?
          # First line of method, determine indent level
          indent_level = line[/\A */].length
        elsif line.strip.empty?
          # Skip empty lines
        elsif line[/\A */].length <= indent_level && line.strip.match?(/^\s*(def|class|module|end|private|protected|public)/)
          # End of method
          break if line.strip == 'end'
        end

        method_lines << line
        current_index += 1
      end

      method_lines.join
    end

    def analyze_method_code(code)
      scenarios = []

      # Analyze if statements
      scenarios.concat(analyze_if_statements(code))

      # Analyze case statements
      scenarios.concat(analyze_case_statements(code))

      # Analyze boolean conditions
      scenarios.concat(analyze_boolean_conditions(code))

      scenarios.uniq
    end

    def analyze_if_statements(code)
      scenarios = []

      # Find if/elsif/unless statements
      code.scan(/(?:if|elsif|unless)\s+(.+?)(?:\s+then|\n)/) do |condition|
        condition_text = condition[0].strip
        next if condition_text.empty?

        # Simplify complex conditions for better readability
        simplified_condition = simplify_condition(condition_text)
        scenarios << "#{simplified_condition}がtrueの場合"
        scenarios << "#{simplified_condition}がfalseの場合"
      end

      scenarios
    end

    def analyze_case_statements(code)
      scenarios = []

      # Find case statements
      case_matches = code.scan(/case\s+(.+?)\n(.*?)(?=end)/m)

      case_matches.each do |case_var, when_block|
        case_var = case_var.strip

        when_block.scan(/when\s+['"]?([^'"]+)['"]?/) do |when_value|
          scenarios << "#{case_var}が'#{when_value[0]}'の場合"
        end

        scenarios << "#{case_var}がその他の値の場合" if when_block.include?('else')
      end

      scenarios
    end

    def analyze_boolean_conditions(code)
      scenarios = []

      # Find method calls that typically return boolean
      boolean_methods = %w[present? blank? nil? empty? valid? invalid? admin? premium? active? locked?]

      boolean_methods.each do |method|
        if code.include?(method)
          scenarios << "#{method}がtrueの場合"
          scenarios << "#{method}がfalseの場合"
        end
      end

      scenarios
    end

    def simplify_condition(condition)
      # Remove common prefixes that might cause duplication
      condition.gsub(/@\w+\./, '').gsub(/\s+/, ' ').strip
    end
  end
end
