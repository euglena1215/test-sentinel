# frozen_string_literal: true

module Calculator
  class Parser
    TOKEN_REGEX = /(\d+\.?\d*|[+\-*\/()^]|\w+)/

    def initialize
      @position = 0
      @tokens = []
    end

    def parse(expression)
      @tokens = tokenize(expression)
      @position = 0
      
      validate_tokens
      convert_to_postfix
    end

    private

    def tokenize(expression)
      expression.gsub(/\s+/, '').scan(TOKEN_REGEX).flatten
    end

    def validate_tokens
      return if @tokens.empty?

      # Check for invalid characters
      @tokens.each do |token|
        unless valid_token?(token)
          raise ParseError, "Invalid token: #{token}"
        end
      end

      # Check for balanced parentheses
      paren_count = 0
      @tokens.each do |token|
        case token
        when '('
          paren_count += 1
        when ')'
          paren_count -= 1
          if paren_count < 0
            raise ParseError, "Unmatched closing parenthesis"
          end
        end
      end

      if paren_count > 0
        raise ParseError, "Unmatched opening parenthesis"
      end
    end

    def valid_token?(token)
      return true if token.match?(/^\d+\.?\d*$/)  # Numbers
      return true if %w[+ - * / ^ ( )].include?(token)  # Operators
      return true if %w[sin cos tan log sqrt].include?(token)  # Functions
      
      false
    end

    def convert_to_postfix
      output = []
      operator_stack = []
      
      @tokens.each do |token|
        case token
        when /^\d+\.?\d*$/
          output << token.to_f
        when /^(sin|cos|tan|log|sqrt)$/
          operator_stack << token
        when '('
          operator_stack << token
        when ')'
          while operator_stack.last != '('
            if operator_stack.empty?
              raise ParseError, "Mismatched parentheses"
            end
            output << operator_stack.pop
          end
          operator_stack.pop  # Remove the '('
          
          # Check if there's a function on top of the stack
          if !operator_stack.empty? && function?(operator_stack.last)
            output << operator_stack.pop
          end
        when '+', '-', '*', '/', '^'
          while !operator_stack.empty? && 
                operator_stack.last != '(' &&
                precedence(operator_stack.last) >= precedence(token)
            output << operator_stack.pop
          end
          operator_stack << token
        end
      end

      while !operator_stack.empty?
        op = operator_stack.pop
        if op == '(' || op == ')'
          raise ParseError, "Mismatched parentheses"
        end
        output << op
      end

      output
    end

    def function?(token)
      %w[sin cos tan log sqrt].include?(token)
    end

    def precedence(operator)
      case operator
      when '+', '-'
        1
      when '*', '/'
        2
      when '^'
        3
      when 'sin', 'cos', 'tan', 'log', 'sqrt'
        4
      else
        0
      end
    end
  end
end