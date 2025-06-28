# frozen_string_literal: true

require_relative 'calculator/parser'
require_relative 'calculator/evaluator'
require_relative 'calculator/formatters/console'

module Calculator
  class Error < StandardError; end
  class ParseError < Error; end
  class EvaluationError < Error; end

  def self.calculate(expression)
    parser = Parser.new
    evaluator = Evaluator.new
    formatter = Formatters::Console.new

    begin
      tokens = parser.parse(expression)
      result = evaluator.evaluate(tokens)
      formatter.format(result)
    rescue StandardError => e
      raise Error, "Calculation failed: #{e.message}"
    end
  end

  def self.version
    "1.0.0"
  end
end