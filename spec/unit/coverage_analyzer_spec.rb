# frozen_string_literal: true

require 'spec_helper'
require 'code_qualia/coverage_analyzer'

RSpec.describe CodeQualia::CoverageAnalyzer do
  describe '#parse_coverage_data' do
    subject(:analyzer) { described_class.new }
    
    # Mock config for path normalization only
    before do
      test_config = instance_double(CodeQualia::Config,
        architectural_weights: [
          { 'path' => 'app/**/*.rb', 'weight' => 1.0 },
          { 'path' => 'lib/**/*.rb', 'weight' => 1.0 }
        ]
      )
      allow(CodeQualia::ConfigHelper).to receive(:load_config).and_return(test_config)
    end

    context 'with valid coverage data for app/ files' do
      let(:coverage_data) do
        {
          '/full/path/to/app/models/user.rb' => {
            'lines' => [1, 1, 0, nil, 1, 0, 0]
          },
          '/full/path/to/app/services/payment.rb' => [1, 0, 1, nil, 0]
        }
      end

      it 'calculates coverage rates correctly' do
        result = analyzer.send(:parse_coverage_data, coverage_data)

        expect(result).to have_key('/full/path/to/app/models/user.rb')
        expect(result['/full/path/to/app/models/user.rb'][:coverage_rate]).to eq(0.5) # 3/6 lines covered (excluding nils: 1,1,0,1,0,0)
        expect(result['/full/path/to/app/models/user.rb'][:covered_lines]).to eq(3)
        expect(result['/full/path/to/app/models/user.rb'][:total_lines]).to eq(6)
      end

      it 'handles array format coverage data' do
        result = analyzer.send(:parse_coverage_data, coverage_data)

        expect(result).to have_key('/full/path/to/app/services/payment.rb')
        expect(result['/full/path/to/app/services/payment.rb'][:coverage_rate]).to eq(0.5) # 2/4 lines covered
        expect(result['/full/path/to/app/services/payment.rb'][:covered_lines]).to eq(2)
        expect(result['/full/path/to/app/services/payment.rb'][:total_lines]).to eq(4)
      end

      it 'stores line coverage data' do
        result = analyzer.send(:parse_coverage_data, coverage_data)

        expect(result['/full/path/to/app/models/user.rb'][:line_coverage]).to eq([1, 1, 0, nil, 1, 0, 0])
        expect(result['/full/path/to/app/services/payment.rb'][:line_coverage]).to eq([1, 0, 1, nil, 0])
      end
    end

    context 'with valid coverage data for lib/ files' do
      let(:coverage_data) do
        {
          '/full/path/to/lib/code_qualia/analyzer.rb' => {
            'lines' => [1, 1, 0, 0, nil, 1]
          }
        }
      end

      it 'processes lib/ files correctly' do
        result = analyzer.send(:parse_coverage_data, coverage_data)

        expect(result).to have_key('/full/path/to/lib/code_qualia/analyzer.rb')
        expect(result['/full/path/to/lib/code_qualia/analyzer.rb'][:coverage_rate]).to eq(0.6) # 3/5 lines covered
        expect(result['/full/path/to/lib/code_qualia/analyzer.rb'][:covered_lines]).to eq(3)
        expect(result['/full/path/to/lib/code_qualia/analyzer.rb'][:total_lines]).to eq(5)
      end
    end

    context 'with mixed app/ and lib/ files' do
      let(:coverage_data) do
        {
          '/full/path/to/app/models/user.rb' => [1, 0, 1],
          '/full/path/to/lib/analyzer.rb' => [1, 1, 0],
          '/full/path/to/config/application.rb' => [1, 1, 1] # should be ignored
        }
      end

      it 'only processes app/ and lib/ files' do
        result = analyzer.send(:parse_coverage_data, coverage_data)

        expect(result.keys).to contain_exactly('/full/path/to/app/models/user.rb', '/full/path/to/lib/analyzer.rb')
        expect(result).not_to have_key('/full/path/to/config/application.rb')
      end
    end

    context 'with edge cases' do
      let(:coverage_data) do
        {
          '/full/path/to/app/models/empty.rb' => [],
          '/full/path/to/app/models/nil_coverage.rb' => nil,
          '/full/path/to/app/models/only_nils.rb' => [nil, nil, nil],
          '/full/path/to/app/models/valid.rb' => [1, 0, 1]
        }
      end

      it 'handles empty coverage data' do
        result = analyzer.send(:parse_coverage_data, coverage_data)

        expect(result).not_to have_key('/full/path/to/app/models/empty.rb')
        expect(result).not_to have_key('/full/path/to/app/models/nil_coverage.rb')
        expect(result).not_to have_key('/full/path/to/app/models/only_nils.rb')
        expect(result).to have_key('/full/path/to/app/models/valid.rb')
      end
    end

    context 'with zero coverage' do
      let(:coverage_data) do
        {
          '/full/path/to/app/models/uncovered.rb' => [0, 0, 0, nil, 0]
        }
      end

      it 'calculates zero coverage correctly' do
        result = analyzer.send(:parse_coverage_data, coverage_data)

        expect(result['/full/path/to/app/models/uncovered.rb'][:coverage_rate]).to eq(0.0)
        expect(result['/full/path/to/app/models/uncovered.rb'][:covered_lines]).to eq(0)
        expect(result['/full/path/to/app/models/uncovered.rb'][:total_lines]).to eq(4)
      end
    end

    context 'with full coverage' do
      let(:coverage_data) do
        {
          '/full/path/to/app/models/covered.rb' => [1, 2, 1, nil, 5]
        }
      end

      it 'calculates full coverage correctly' do
        result = analyzer.send(:parse_coverage_data, coverage_data)

        expect(result['/full/path/to/app/models/covered.rb'][:coverage_rate]).to eq(1.0)
        expect(result['/full/path/to/app/models/covered.rb'][:covered_lines]).to eq(4)
        expect(result['/full/path/to/app/models/covered.rb'][:total_lines]).to eq(4)
      end
    end
  end
end
