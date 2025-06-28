# frozen_string_literal: true

module Calculator
  module Formatters
    class Console
      def initialize(precision: 6)
        @precision = precision
      end

      def format(result)
        return "0" if result.zero?
        
        # Handle integers
        if result.integer?
          return result.to_i.to_s
        end
        
        # Format floating point numbers
        formatted = format_float(result)
        
        # Remove trailing zeros and unnecessary decimal point
        formatted.sub(/\.?0+$/, '')
      end

      def format_error(error)
        "Error: #{error.message}"
      end

      def format_history(history_entries)
        return "No calculation history" if history_entries.empty?
        
        output = ["Calculation History:", "=" * 20]
        
        history_entries.each_with_index do |entry, index|
          timestamp = entry[:timestamp].strftime("%H:%M:%S")
          line = "#{index + 1}. [#{timestamp}] #{entry[:expression]} = #{format(entry[:result])}"
          output << line
        end
        
        output.join("\n")
      end

      def format_help
        <<~HELP
          Calculator CLI - Help
          ====================
          
          Basic Operations:
            + (addition)       2 + 3 = 5
            - (subtraction)    5 - 2 = 3
            * (multiplication) 3 * 4 = 12
            / (division)       8 / 2 = 4
            ^ (power)          2 ^ 3 = 8
          
          Scientific Functions:
            sin(x)   sine
            cos(x)   cosine
            tan(x)   tangent
            log(x)   natural logarithm
            sqrt(x)  square root
          
          Examples:
            2 + 3 * 4
            sin(3.14159 / 2)
            sqrt(16) + log(2.718)
            (2 + 3) * (4 - 1)
          
          Commands:
            help     Show this help
            history  Show calculation history
            clear    Clear screen
            exit     Exit calculator
        HELP
      end

      private

      def format_float(number)
        # Use scientific notation for very large or very small numbers
        if number.abs >= 1e10 || (number.abs < 1e-4 && number != 0)
          "%.#{@precision}e" % number
        else
          "%.#{@precision}f" % number
        end
      end

      def significant_digits(number)
        return 1 if number.zero?
        
        # Count significant digits
        str = number.abs.to_s
        str.gsub(/^0+/, '').gsub(/\./, '').gsub(/0+$/, '').length
      end
    end
  end
end