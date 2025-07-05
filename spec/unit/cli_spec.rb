# frozen_string_literal: true

require 'spec_helper'
require 'code_qualia'

RSpec.describe CodeQualia::CLI do
  let(:cli) { described_class.new(argv) }

  describe '#initialize' do
    let(:argv) { [] }

    it 'sets default options' do
      cli = described_class.new(argv)
      options = cli.instance_variable_get(:@options)
      
      expect(options[:top_n]).to eq(3)
      expect(options[:config]).to eq('./qualia.yml')
      expect(options[:directory]).to eq(Dir.pwd)
      expect(options[:format]).to eq('human')
    end
  end

  describe '#parse_options' do
    context 'with --format option' do
      let(:argv) { ['generate', '--format', 'json'] }

      it 'sets the format option' do
        cli.send(:parse_options)
        options = cli.instance_variable_get(:@options)
        expect(options[:format]).to eq('json')
      end
    end

    context 'with invalid format', allow_exit: true do
      let(:argv) { ['generate', '--format', 'invalid'] }

      it 'exits with error message' do
        allow(cli).to receive(:exit_with_code)
        expect { cli.send(:parse_options) }.to output(/Error: Invalid format/).to_stdout
        expect(cli).to have_received(:exit_with_code).with(1)
      end
    end

    context 'with --top-n option' do
      let(:argv) { ['generate', '--top-n', '5'] }

      it 'sets the top_n option' do
        cli.send(:parse_options)
        options = cli.instance_variable_get(:@options)
        expect(options[:top_n]).to eq(5)
      end
    end

    context 'with --directory option' do
      let(:argv) { ['generate', '--directory', '/tmp'] }

      it 'sets the directory option' do
        cli.send(:parse_options)
        options = cli.instance_variable_get(:@options)
        expect(options[:directory]).to eq('/tmp')
      end
    end

    context 'with --config option' do
      let(:argv) { ['generate', '--config', 'custom.yml'] }

      it 'sets the config option' do
        cli.send(:parse_options)
        options = cli.instance_variable_get(:@options)
        expect(options[:config]).to eq('custom.yml')
      end
    end
  end

  describe '#extract_class_name' do
    let(:argv) { [] }

    it 'extracts class name from file path' do
      class_name = cli.send(:extract_class_name, 'app/models/user_account.rb')
      expect(class_name).to eq('UserAccount')
    end

    it 'handles simple file names' do
      class_name = cli.send(:extract_class_name, 'user.rb')
      expect(class_name).to eq('User')
    end
  end

  describe '#generate_analysis' do
    let(:argv) { ['generate'] }
    let(:sample_results) do
      [
        {
          file_path: 'app/models/user.rb',
          method_name: 'complex_method',
          line_number: 15,
          score: 25.5,
          details: {
            coverage: 0.6,
            complexity: 8,
            git_commits: 3
          }
        }
      ]
    end

    before do
      allow(Dir).to receive(:pwd).and_return('/original')
      allow(Dir).to receive(:chdir)
      allow(CodeQualia).to receive(:analyze).and_return(sample_results)
    end

    context 'with empty results' do
      before do
        allow(CodeQualia).to receive(:analyze).and_return([])
      end

      it 'outputs human format message for empty results' do
        cli = described_class.new(argv)
        expect { cli.send(:generate_analysis) }.to output(/✅ No methods found that need additional testing./).to_stdout
      end

      it 'outputs json format for empty results' do
        cli = described_class.new(['generate', '--format', 'json'])
        cli.send(:parse_options)
        expect { cli.send(:generate_analysis) }.to output(/\[\]/).to_stdout
      end

      it 'outputs csv format for empty results' do
        cli = described_class.new(['generate', '--format', 'csv'])
        cli.send(:parse_options)
        expect { cli.send(:generate_analysis) }.to output(/file_path,method_name,line_number,score,coverage,complexity,git_commits/).to_stdout
      end

      it 'outputs table format for empty results' do
        cli = described_class.new(['generate', '--format', 'table'])
        cli.send(:parse_options)
        expect { cli.send(:generate_analysis) }.to output(/No methods found that need additional testing./).to_stdout
      end
    end

    context 'with analysis results' do
      it 'changes to target directory and restores original directory' do
        cli = described_class.new(['generate', '--directory', '/target'])
        cli.send(:parse_options)
        
        allow(Dir).to receive(:pwd).and_return('/original')
        allow(CodeQualia).to receive(:analyze).and_return([])
        
        expect(Dir).to receive(:chdir).with('/target').ordered
        expect(Dir).to receive(:chdir).with('/original').ordered

        expect { cli.send(:generate_analysis) }.to output.to_stdout
      end

      it 'passes options to CodeQualia.analyze' do
        cli = described_class.new(['generate', '--config', 'test.yml', '--verbose'])
        cli.send(:parse_options)
        
        expect(CodeQualia).to receive(:analyze).with('test.yml', verbose: true).and_return(sample_results)
        
        expect { cli.send(:generate_analysis) }.to output.to_stdout
      end

      it 'limits results to top_n' do
        large_results = Array.new(10) { |i| sample_results[0].merge(line_number: i + 1) }
        allow(CodeQualia).to receive(:analyze).and_return(large_results)
        
        cli = described_class.new(['generate', '--top-n', '3'])
        cli.send(:parse_options)
        allow(cli).to receive(:output_human_format)
        
        cli.send(:generate_analysis)
        
        expect(cli).to have_received(:output_human_format).with(large_results.take(3))
      end

      it 'calls appropriate output format method' do
        cli = described_class.new(['generate', '--format', 'json'])
        cli.send(:parse_options)
        allow(cli).to receive(:output_json_format)
        
        cli.send(:generate_analysis)
        
        expect(cli).to have_received(:output_json_format).with(sample_results)
      end
    end

    context 'with CodeQualia::Error' do
      before do
        allow(CodeQualia).to receive(:analyze).and_raise(CodeQualia::Error, 'Test error')
        allow(cli).to receive(:exit_with_code)
      end

      it 'handles CodeQualia errors gracefully' do
        expect { cli.send(:generate_analysis) }.to output(/❌ Error: Test error/).to_stdout
        expect(cli).to have_received(:exit_with_code).with(1)
      end
    end

    context 'with StandardError' do
      before do
        allow(CodeQualia).to receive(:analyze).and_raise(StandardError, 'Unexpected error')
        allow(cli).to receive(:exit_with_code)
      end

      it 'handles standard errors gracefully' do
        expect { cli.send(:generate_analysis) }.to output(/❌ Unexpected error: Unexpected error/).to_stdout
        expect(cli).to have_received(:exit_with_code).with(1)
      end
    end

    context 'when directory change fails', allow_exit: true do
      before do
        allow(Dir).to receive(:chdir).with('/target').and_raise(Errno::ENOENT, 'No such directory')
        allow(cli).to receive(:exit_with_code)
      end

      it 'handles directory change errors and restores original directory' do
        cli = described_class.new(['generate', '--directory', '/target'])
        cli.send(:parse_options)
        
        expect(Dir).to receive(:chdir).with('/original').ordered
        
        expect { cli.send(:generate_analysis) }.to output(/❌ Unexpected error/).to_stdout
        expect(cli).to have_received(:exit_with_code).with(1)
      end
    end
  end
end