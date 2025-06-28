# frozen_string_literal: true

module Calculator
  module Operations
    class Basic
      def add(left, right)
        validate_numbers(left, right)
        left + right
      end

      def subtract(left, right)
        validate_numbers(left, right)
        left - right
      end

      def multiply(left, right)
        validate_numbers(left, right)
        left * right
      end

      def divide(left, right)
        validate_numbers(left, right)
        
        if right.zero?
          raise EvaluationError, "Division by zero"
        end
        
        result = left / right.to_f
        
        if result.infinite?
          raise EvaluationError, "Division result is infinite"
        end
        
        result
      end

      def power(base, exponent)
        validate_numbers(base, exponent)
        
        # Handle special cases
        if base.zero? && exponent.negative?
          raise EvaluationError, "Cannot raise zero to negative power"
        end
        
        if base.negative? && !exponent.integer?
          raise EvaluationError, "Cannot raise negative number to non-integer power"
        end
        
        result = base ** exponent
        
        if result.infinite?
          raise EvaluationError, "Power operation result is infinite"
        end
        
        result
      end

      def modulo(left, right)
        validate_numbers(left, right)
        
        if right.zero?
          raise EvaluationError, "Modulo by zero"
        end
        
        left % right
      end

      def absolute(number)
        validate_number(number)
        number.abs
      end

      def negate(number)
        validate_number(number)
        -number
      end

      def factorial(number)
        validate_number(number)
        
        unless number.integer? && number >= 0
          raise EvaluationError, "Factorial only defined for non-negative integers"
        end
        
        return 1 if number.zero? || number == 1
        
        result = 1
        (2..number).each do |i|
          result *= i
        end
        
        result
      end

      private

      def validate_numbers(*numbers)
        numbers.each { |num| validate_number(num) }
      end

      def validate_number(number)
        unless number.is_a?(Numeric)
          raise EvaluationError, "Expected number, got #{number.class}"
        end
        
        if (number.respond_to?(:infinite?) && number.infinite?) || 
           (number.respond_to?(:nan?) && number.nan?)
          raise EvaluationError, "Invalid number: #{number}"
        end
      end
    end
  end
end