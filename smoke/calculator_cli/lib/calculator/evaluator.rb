# frozen_string_literal: true

require_relative 'operations/basic'
require_relative 'operations/scientific'

module Calculator
  class Evaluator
    def initialize
      @basic_ops = Operations::Basic.new
      @scientific_ops = Operations::Scientific.new
    end

    def evaluate(tokens)
      return 0 if tokens.empty?
      
      stack = []
      
      tokens.each do |token|
        case token
        when Numeric
          stack << token
        when '+', '-', '*', '/', '^'
          result = evaluate_binary_operation(token, stack)
          stack << result
        when 'sin', 'cos', 'tan', 'log', 'sqrt'
          result = evaluate_unary_operation(token, stack)
          stack << result
        else
          raise EvaluationError, "Unknown token: #{token}"
        end
      end

      if stack.length != 1
        raise EvaluationError, "Invalid expression"
      end

      validate_result(stack.first)
    end

    private

    def evaluate_binary_operation(operator, stack)
      if stack.length < 2
        raise EvaluationError, "Insufficient operands for #{operator}"
      end

      right = stack.pop
      left = stack.pop

      case operator
      when '+'
        @basic_ops.add(left, right)
      when '-'
        @basic_ops.subtract(left, right)
      when '*'
        @basic_ops.multiply(left, right)
      when '/'
        @basic_ops.divide(left, right)
      when '^'
        @basic_ops.power(left, right)
      else
        raise EvaluationError, "Unknown binary operator: #{operator}"
      end
    end

    def evaluate_unary_operation(operator, stack)
      if stack.empty?
        raise EvaluationError, "Insufficient operands for #{operator}"
      end

      operand = stack.pop

      case operator
      when 'sin'
        @scientific_ops.sin(operand)
      when 'cos'
        @scientific_ops.cos(operand)
      when 'tan'
        @scientific_ops.tan(operand)
      when 'log'
        @scientific_ops.log(operand)
      when 'sqrt'
        @scientific_ops.sqrt(operand)
      else
        raise EvaluationError, "Unknown unary operator: #{operator}"
      end
    end

    def validate_result(result)
      if result.nil? || result.infinite? || result.nan?
        raise EvaluationError, "Invalid calculation result"
      end
      
      result
    end

    def memory_store(value)
      @memory = value
    end

    def memory_recall
      @memory || 0
    end

    def memory_clear
      @memory = nil
    end

    def history
      @history ||= []
    end

    def add_to_history(expression, result)
      history << { expression: expression, result: result, timestamp: Time.now }
      # Keep only last 10 calculations
      @history = @history.last(10) if @history.length > 10
    end
  end
end