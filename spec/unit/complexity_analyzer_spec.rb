# frozen_string_literal: true

require 'English'
require 'spec_helper'
require 'code_qualia/complexity_analyzer'

RSpec.describe CodeQualia::ComplexityAnalyzer do
  describe '#run_rubocop' do
    subject(:analyzer) { described_class.new }

    context 'when directories are found by dynamic detection' do
      before do
        # Mock config to return specific patterns for testing
        test_config = instance_double(CodeQualia::Config,
          architectural_weights: [
            { 'path' => 'app/**/*.rb', 'weight' => 1.0 },
            { 'path' => 'lib/**/*.rb', 'weight' => 1.0 }
          ]
        )
        allow(CodeQualia::ConfigHelper).to receive(:load_config).and_return(test_config)
        
        # Mock PatternExpander to return expected directories
        allow(CodeQualia::PatternExpander).to receive(:extract_base_directories)
          .with(['app/**/*.rb', 'lib/**/*.rb'])
          .and_return(['app', 'lib'])
        
        allow(Dir).to receive(:exist?).and_call_original
        allow(Dir).to receive(:exist?).with('app/').and_return(true)
        allow(Dir).to receive(:exist?).with('lib/').and_return(true)
        allow(analyzer).to receive(:`).and_return('{"files": []}')
        allow(analyzer).to receive(:last_exit_status).and_return(0)
      end

      it 'runs rubocop on detected directories' do
        expected_command = 'bundle exec rubocop --format json --only Metrics/CyclomaticComplexity app/ lib/'

        expect(analyzer).to receive(:`).with("#{expected_command} 2>/dev/null")

        analyzer.send(:run_rubocop)
      end
    end

    context 'when only some directories exist' do
      before do
        test_config = instance_double(CodeQualia::Config,
          architectural_weights: [
            { 'path' => 'app/**/*.rb', 'weight' => 1.0 },
            { 'path' => 'lib/**/*.rb', 'weight' => 1.0 }
          ]
        )
        allow(CodeQualia::ConfigHelper).to receive(:load_config).and_return(test_config)
        
        allow(CodeQualia::PatternExpander).to receive(:extract_base_directories)
          .with(['app/**/*.rb', 'lib/**/*.rb'])
          .and_return(['app', 'lib'])
        
        allow(Dir).to receive(:exist?).and_call_original
        allow(Dir).to receive(:exist?).with('app/').and_return(true)
        allow(Dir).to receive(:exist?).with('lib/').and_return(false)
        allow(analyzer).to receive(:`).and_return('{"files": []}')
        allow(analyzer).to receive(:last_exit_status).and_return(0)
      end

      it 'runs rubocop only on existing directories' do
        expected_command = 'bundle exec rubocop --format json --only Metrics/CyclomaticComplexity app/'

        expect(analyzer).to receive(:`).with("#{expected_command} 2>/dev/null")

        analyzer.send(:run_rubocop)
      end
    end

    context 'when no directories exist' do
      before do
        test_config = instance_double(CodeQualia::Config,
          architectural_weights: [
            { 'path' => 'app/**/*.rb', 'weight' => 1.0 },
            { 'path' => 'lib/**/*.rb', 'weight' => 1.0 }
          ]
        )
        allow(CodeQualia::ConfigHelper).to receive(:load_config).and_return(test_config)
        
        allow(CodeQualia::PatternExpander).to receive(:extract_base_directories)
          .with(['app/**/*.rb', 'lib/**/*.rb'])
          .and_return(['app', 'lib'])
        
        allow(Dir).to receive(:exist?).and_call_original
        allow(Dir).to receive(:exist?).with('app/').and_return(false)
        allow(Dir).to receive(:exist?).with('lib/').and_return(false)
      end

      it 'returns empty string' do
        result = analyzer.send(:run_rubocop)
        expect(result).to eq('')
      end
    end

    context 'when bundle exec is not available' do
      before do
        test_config = instance_double(CodeQualia::Config,
          architectural_weights: [
            { 'path' => 'app/**/*.rb', 'weight' => 1.0 }
          ]
        )
        allow(CodeQualia::ConfigHelper).to receive(:load_config).and_return(test_config)
        
        allow(CodeQualia::PatternExpander).to receive(:extract_base_directories)
          .with(['app/**/*.rb'])
          .and_return(['app'])
        
        allow(Dir).to receive(:exist?).and_call_original
        allow(Dir).to receive(:exist?).with('app/').and_return(true)
        allow(analyzer).to receive(:last_exit_status).and_return(127, 0)
        allow(analyzer).to receive(:`).and_return('', '{"files": []}')
      end

      it 'falls back to running rubocop without bundle exec' do
        fallback_command = 'rubocop --format json --only Metrics/CyclomaticComplexity app/'

        expect(analyzer).to receive(:`).with('bundle exec rubocop --format json --only Metrics/CyclomaticComplexity app/ 2>/dev/null')
        expect(analyzer).to receive(:`).with("#{fallback_command} 2>/dev/null")

        analyzer.send(:run_rubocop)
      end
    end

    context 'when rubocop returns actual output' do
      let(:rubocop_output) do
        '{"files": [{"path": "app/models/user.rb", "offenses": []}]}'
      end

      before do
        test_config = instance_double(CodeQualia::Config,
          architectural_weights: [
            { 'path' => 'app/**/*.rb', 'weight' => 1.0 }
          ]
        )
        allow(CodeQualia::ConfigHelper).to receive(:load_config).and_return(test_config)
        
        allow(CodeQualia::PatternExpander).to receive(:extract_base_directories)
          .with(['app/**/*.rb'])
          .and_return(['app'])
        
        allow(Dir).to receive(:exist?).and_call_original
        allow(Dir).to receive(:exist?).with('app/').and_return(true)
        allow(analyzer).to receive(:`).and_return(rubocop_output)
        allow(analyzer).to receive(:last_exit_status).and_return(0)
      end

      it 'returns the rubocop output' do
        result = analyzer.send(:run_rubocop)
        expect(result).to eq(rubocop_output)
      end
    end
  end

  describe '#parse_rubocop_output' do
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

    context 'with valid JSON output' do
      let(:rubocop_output) do
        <<~JSON
          {
            "files": [
              {
                "path": "/full/path/to/app/models/user.rb",
                "offenses": [
                  {
                    "severity": "convention",
                    "message": "Cyclomatic complexity for `complex_method` is too high. [8/6]",
                    "cop_name": "Metrics/CyclomaticComplexity",
                    "corrected": false,
                    "correctable": false,
                    "location": {
                      "start_line": 15,
                      "start_column": 5,
                      "last_line": 25,
                      "last_column": 7,
                      "length": 14,
                      "line": 15,
                      "column": 5
                    }
                  }
                ]
              },
              {
                "path": "/full/path/to/lib/code_qualia/analyzer.rb",
                "offenses": [
                  {
                    "severity": "convention",
                    "message": "Cyclomatic complexity for `analyze_data` is too high. [12/6]",
                    "cop_name": "Metrics/CyclomaticComplexity",
                    "corrected": false,
                    "correctable": false,
                    "location": {
                      "start_line": 42,
                      "start_column": 5,
                      "last_line": 55,
                      "last_column": 7,
                      "length": 12,
                      "line": 42,
                      "column": 5
                    }
                  }
                ]
              }
            ],
            "summary": {
              "offense_count": 2,
              "target_file_count": 2,
              "inspected_file_count": 2
            }
          }
        JSON
      end

      it 'parses complexity data correctly for app/ files' do
        result = analyzer.send(:parse_rubocop_output, rubocop_output)

        expect(result).to have_key('/full/path/to/app/models/user.rb')
        expect(result['/full/path/to/app/models/user.rb']).to contain_exactly(
          {
            method_name: 'complex_method',
            line_number: 15,
            complexity: 8
          }
        )
      end

      it 'parses complexity data correctly for lib/ files' do
        result = analyzer.send(:parse_rubocop_output, rubocop_output)

        expect(result).to have_key('/full/path/to/lib/code_qualia/analyzer.rb')
        expect(result['/full/path/to/lib/code_qualia/analyzer.rb']).to contain_exactly(
          {
            method_name: 'analyze_data',
            line_number: 42,
            complexity: 12
          }
        )
      end
    end

    context 'with empty output' do
      it 'returns empty hash' do
        result = analyzer.send(:parse_rubocop_output, '')
        expect(result).to eq({})
      end
    end

    context 'with non-JSON output' do
      it 'returns empty hash' do
        result = analyzer.send(:parse_rubocop_output, 'not valid json')
        expect(result).to eq({})
      end
    end

    context 'with output containing non-complexity offenses' do
      let(:rubocop_output) do
        <<~JSON
          {
            "files": [
              {
                "path": "/full/path/to/app/models/user.rb",
                "offenses": [
                  {
                    "severity": "convention",
                    "message": "Line is too long. [120/80]",
                    "cop_name": "Layout/LineLength",
                    "corrected": false,
                    "correctable": false,
                    "location": {
                      "start_line": 10,
                      "start_column": 1,
                      "last_line": 10,
                      "last_column": 120,
                      "length": 120,
                      "line": 10,
                      "column": 1
                    }
                  }
                ]
              }
            ],
            "summary": {
              "offense_count": 1,
              "target_file_count": 1,
              "inspected_file_count": 1
            }
          }
        JSON
      end

      it 'ignores non-complexity offenses' do
        result = analyzer.send(:parse_rubocop_output, rubocop_output)
        expect(result).to eq({})
      end
    end

    context 'with mixed JSON and text output' do
      let(:mixed_output) do
        <<~OUTPUT
          Some warning text before JSON
          {
            "files": [
              {
                "path": "/full/path/to/app/services/payment.rb",
                "offenses": [
                  {
                    "severity": "convention",
                    "message": "Cyclomatic complexity for `process_payment` is too high. [5/3]",
                    "cop_name": "Metrics/CyclomaticComplexity",
                    "corrected": false,
                    "correctable": false,
                    "location": {
                      "start_line": 20,
                      "start_column": 5,
                      "last_line": 30,
                      "last_column": 7,
                      "length": 15,
                      "line": 20,
                      "column": 5
                    }
                  }
                ]
              }
            ],
            "summary": {
              "offense_count": 1,
              "target_file_count": 1,
              "inspected_file_count": 1
            }
          }
        OUTPUT
      end

      it 'extracts JSON portion correctly' do
        result = analyzer.send(:parse_rubocop_output, mixed_output)

        expect(result).to have_key('/full/path/to/app/services/payment.rb')
        expect(result['/full/path/to/app/services/payment.rb']).to contain_exactly(
          {
            method_name: 'process_payment',
            line_number: 20,
            complexity: 5
          }
        )
      end
    end

    context 'with malformed JSON output' do
      let(:malformed_output) do
        <<~OUTPUT
          Some text before
          {
            "files": [
              {
                "path": "/full/path/to/app/models/user.rb",
                "offenses": [
                  {
                    "severity": "convention",
                    "message": "Cyclomatic complexity for `test_method` is too high. [7/6]",
                    "cop_name": "Metrics/CyclomaticComplexity",
                    "location": {
                      "start_line": 10
                    }
                  }
                ]
              }
            // Missing closing brace
        OUTPUT
      end

      it 'handles JSON parsing errors gracefully' do
        result = analyzer.send(:parse_rubocop_output, malformed_output)
        expect(result).to eq({})
      end
    end

    context 'when relative path is nil or empty' do
      let(:rubocop_output) do
        <<~JSON
          {
            "files": [
              {
                "path": "/some/unrelated/path/file.rb",
                "offenses": [
                  {
                    "severity": "convention",
                    "message": "Cyclomatic complexity for `test_method` is too high. [7/6]",
                    "cop_name": "Metrics/CyclomaticComplexity",
                    "location": {
                      "start_line": 10
                    }
                  }
                ]
              }
            ]
          }
        JSON
      end

      before do
        allow(CodeQualia::ConfigHelper).to receive(:normalize_file_path).and_return(nil)
      end

      it 'skips files with nil relative path' do
        result = analyzer.send(:parse_rubocop_output, rubocop_output)
        expect(result).to eq({})
      end
    end
    
    context 'with invalid method info extraction' do
      let(:rubocop_output) do
        <<~JSON
          {
            "files": [
              {
                "path": "/full/path/to/app/models/user.rb",
                "offenses": [
                  {
                    "severity": "convention",
                    "message": "Invalid message format without proper complexity info",
                    "cop_name": "Metrics/CyclomaticComplexity",
                    "location": {
                      "start_line": 10
                    }
                  }
                ]
              }
            ]
          }
        JSON
      end

      it 'skips offenses with invalid method info' do
        result = analyzer.send(:parse_rubocop_output, rubocop_output)
        expect(result).to eq({})
      end
    end
  end

  describe '#extract_method_info' do
    subject(:analyzer) { described_class.new }

    context 'with valid complexity message' do
      it 'extracts method name and complexity correctly' do
        message = "Cyclomatic complexity for `calculate_fee` is too high. [12/6]"
        result = analyzer.send(:extract_method_info, message)
        
        expect(result).to eq({
          method_name: 'calculate_fee',
          complexity: 12
        })
      end

      it 'handles different complexity values' do
        message = "Cyclomatic complexity for `process_data` is too high. [25/10]"
        result = analyzer.send(:extract_method_info, message)
        
        expect(result).to eq({
          method_name: 'process_data',
          complexity: 25
        })
      end
    end

    context 'with invalid message format' do
      it 'returns nil for non-matching message' do
        message = "Some other rubocop message"
        result = analyzer.send(:extract_method_info, message)
        expect(result).to be_nil
      end

      it 'returns nil for incomplete complexity message' do
        message = "Cyclomatic complexity for method is too high"
        result = analyzer.send(:extract_method_info, message)
        expect(result).to be_nil
      end
    end
  end
end
