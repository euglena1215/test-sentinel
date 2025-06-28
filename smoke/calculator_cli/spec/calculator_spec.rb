# frozen_string_literal: true

require_relative '../lib/calculator'

RSpec.describe Calculator do
  describe '.calculate' do
    it 'performs basic arithmetic' do
      expect(Calculator.calculate('2 + 3')).to eq('5')
      expect(Calculator.calculate('10 - 4')).to eq('6')
      expect(Calculator.calculate('3 * 7')).to eq('21')
      expect(Calculator.calculate('15 / 3')).to eq('5')
    end

    it 'handles complex expressions' do
      expect(Calculator.calculate('2 + 3 * 4')).to eq('14')
      expect(Calculator.calculate('(2 + 3) * 4')).to eq('20')
      expect(Calculator.calculate('2 ^ 3 + 1')).to eq('9')
    end

    it 'handles scientific functions' do
      expect(Calculator.calculate('sqrt(16)')).to eq('4')
      expect(Calculator.calculate('sin(0)')).to eq('0')
      expect(Calculator.calculate('cos(0)')).to eq('1')
    end

    it 'raises error for invalid expressions' do
      expect { Calculator.calculate('2 +') }.to raise_error(Calculator::Error)
      expect { Calculator.calculate('((2 + 3)') }.to raise_error(Calculator::Error)
      expect { Calculator.calculate('2 / 0') }.to raise_error(Calculator::Error)
    end
  end

  describe '.version' do
    it 'returns version string' do
      expect(Calculator.version).to eq('1.0.0')
    end
  end
end