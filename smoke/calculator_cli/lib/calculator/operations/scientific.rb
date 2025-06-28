# frozen_string_literal: true

module Calculator
  module Operations
    class Scientific
      DEGREES_TO_RADIANS = Math::PI / 180.0

      def sin(angle, mode: :radians)
        validate_number(angle)
        
        radians = mode == :degrees ? angle * DEGREES_TO_RADIANS : angle
        result = Math.sin(radians)
        
        # Round very small values to zero (floating point precision issues)
        result.abs < 1e-15 ? 0.0 : result
      end

      def cos(angle, mode: :radians)
        validate_number(angle)
        
        radians = mode == :degrees ? angle * DEGREES_TO_RADIANS : angle
        result = Math.cos(radians)
        
        # Round very small values to zero
        result.abs < 1e-15 ? 0.0 : result
      end

      def tan(angle, mode: :radians)
        validate_number(angle)
        
        radians = mode == :degrees ? angle * DEGREES_TO_RADIANS : angle
        
        # Check for undefined values (odd multiples of π/2)
        if cos(radians).abs < 1e-15
          raise EvaluationError, "Tangent is undefined for this angle"
        end
        
        result = Math.tan(radians)
        
        # Round very small values to zero
        result.abs < 1e-15 ? 0.0 : result
      end

      def log(number, base: Math::E)
        validate_number(number)
        validate_number(base)
        
        if number <= 0
          raise EvaluationError, "Logarithm undefined for non-positive numbers"
        end
        
        if base <= 0 || base == 1
          raise EvaluationError, "Invalid logarithm base"
        end
        
        if base == Math::E
          Math.log(number)
        elsif base == 10
          Math.log10(number)
        else
          Math.log(number) / Math.log(base)
        end
      end

      def sqrt(number)
        validate_number(number)
        
        if number.negative?
          raise EvaluationError, "Square root undefined for negative numbers"
        end
        
        Math.sqrt(number)
      end

      def exp(exponent)
        validate_number(exponent)
        
        result = Math.exp(exponent)
        
        if result.infinite?
          raise EvaluationError, "Exponential result is infinite"
        end
        
        result
      end

      def asin(value)
        validate_number(value)
        
        if value < -1 || value > 1
          raise EvaluationError, "Arcsine undefined for values outside [-1, 1]"
        end
        
        Math.asin(value)
      end

      def acos(value)
        validate_number(value)
        
        if value < -1 || value > 1
          raise EvaluationError, "Arccosine undefined for values outside [-1, 1]"
        end
        
        Math.acos(value)
      end

      def atan(value)
        validate_number(value)
        Math.atan(value)
      end

      def pi
        Math::PI
      end

      def e
        Math::E
      end

      def deg_to_rad(degrees)
        validate_number(degrees)
        degrees * DEGREES_TO_RADIANS
      end

      def rad_to_deg(radians)
        validate_number(radians)
        radians / DEGREES_TO_RADIANS
      end

      private

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