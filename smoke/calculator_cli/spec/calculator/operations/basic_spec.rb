# frozen_string_literal: true

require_relative '../../../lib/calculator/operations/basic'

RSpec.describe Calculator::Operations::Basic do
  let(:basic) { described_class.new }

  describe '#add' do
    it 'adds two numbers' do
      expect(basic.add(2, 3)).to eq(5)
      expect(basic.add(-1, 1)).to eq(0)
      expect(basic.add(0.5, 0.3)).to be_within(0.01).of(0.8)
    end
  end

  describe '#subtract' do
    it 'subtracts two numbers' do
      expect(basic.subtract(5, 3)).to eq(2)
      expect(basic.subtract(1, -1)).to eq(2)
    end
  end

  describe '#multiply' do
    it 'multiplies two numbers' do
      expect(basic.multiply(3, 4)).to eq(12)
      expect(basic.multiply(-2, 3)).to eq(-6)
    end
  end

  describe '#divide' do
    it 'divides two numbers' do
      expect(basic.divide(8, 2)).to eq(4.0)
      expect(basic.divide(1, 3)).to be_within(0.01).of(0.33)
    end

    it 'raises error for division by zero' do
      expect { basic.divide(5, 0) }.to raise_error(Calculator::EvaluationError)
    end
  end

  describe '#power' do
    it 'raises number to power' do
      expect(basic.power(2, 3)).to eq(8)
      expect(basic.power(4, 0.5)).to eq(2)
    end

    it 'raises error for invalid operations' do
      expect { basic.power(0, -1) }.to raise_error(Calculator::EvaluationError)
      expect { basic.power(-2, 0.5) }.to raise_error(Calculator::EvaluationError)
    end
  end

  describe '#factorial' do
    it 'calculates factorial' do
      expect(basic.factorial(0)).to eq(1)
      expect(basic.factorial(1)).to eq(1)
      expect(basic.factorial(5)).to eq(120)
    end

    it 'raises error for invalid input' do
      expect { basic.factorial(-1) }.to raise_error(Calculator::EvaluationError)
      expect { basic.factorial(0.5) }.to raise_error(Calculator::EvaluationError)
    end
  end
end