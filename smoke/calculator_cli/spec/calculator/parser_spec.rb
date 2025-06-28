# frozen_string_literal: true

require_relative '../../lib/calculator/parser'

RSpec.describe Calculator::Parser do
  let(:parser) { described_class.new }

  describe '#parse' do
    it 'tokenizes simple expressions' do
      result = parser.parse('2 + 3')
      expect(result).to eq([2.0, 3.0, '+'])
    end

    it 'handles operator precedence' do
      result = parser.parse('2 + 3 * 4')
      expect(result).to eq([2.0, 3.0, 4.0, '*', '+'])
    end

    it 'handles parentheses' do
      result = parser.parse('(2 + 3) * 4')
      expect(result).to eq([2.0, 3.0, '+', 4.0, '*'])
    end

    it 'handles scientific functions' do
      result = parser.parse('sin(3.14)')
      expect(result).to eq([3.14, 'sin'])
    end

    it 'raises error for invalid tokens' do
      expect { parser.parse('2 & 3') }.to raise_error(Calculator::ParseError)
    end

    it 'raises error for unmatched parentheses' do
      expect { parser.parse('((2 + 3)') }.to raise_error(Calculator::ParseError)
      expect { parser.parse('2 + 3))') }.to raise_error(Calculator::ParseError)
    end
  end
end