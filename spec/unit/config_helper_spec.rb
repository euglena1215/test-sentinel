# frozen_string_literal: true

require 'spec_helper'
require 'test_sentinel'

RSpec.describe TestSentinel::ConfigHelper do
  describe '.get_target_patterns' do
    context 'with default configuration' do
      before do
        allow(File).to receive(:exist?).with('sentinel.yml').and_return(false)
      end

      it 'returns expanded glob patterns for target files' do
        patterns = described_class.get_target_patterns
        expect(patterns).to be_an(Array)
        expect(patterns.all? { |p| p.is_a?(String) }).to be true
        expect(patterns).to include('**/*.rb')
      end

      it 'converts directory patterns to file patterns' do
        patterns = described_class.get_target_patterns
        expect(patterns.all? { |p| p.end_with?('.rb') || p.include?('*') }).to be true
      end
    end

    context 'with brace patterns in configuration' do
      let(:config) do
        instance_double(TestSentinel::Config,
                        directory_weights: [
                          { 'path' => 'app/{models,controllers}/**/*.rb', 'weight' => 1.0 }
                        ])
      end

      before do
        allow(described_class).to receive(:load_config).and_return(config)
      end

      it 'expands brace patterns correctly' do
        patterns = described_class.get_target_patterns
        expect(patterns).to include('app/models/**/*.rb')
        expect(patterns).to include('app/controllers/**/*.rb')
      end
    end

    context 'with directory patterns' do
      let(:config) do
        instance_double(TestSentinel::Config,
                        directory_weights: [
                          { 'path' => 'lib/', 'weight' => 1.0 },
                          { 'path' => 'app', 'weight' => 1.0 }
                        ])
      end

      before do
        allow(described_class).to receive(:load_config).and_return(config)
      end

      it 'converts directory paths to file patterns' do
        patterns = described_class.get_target_patterns
        expect(patterns).to include('lib/**/*.rb')
        expect(patterns).to include('app/**/*.rb')
      end
    end
  end

  describe '.should_include_file?' do
    let(:target_patterns) { ['app/models/**/*.rb', 'lib/**/*.rb'] }

    context 'with Ruby files matching patterns' do
      it 'returns true for matching Ruby files' do
        expect(described_class.should_include_file?('app/models/user.rb', target_patterns)).to be true
        expect(described_class.should_include_file?('lib/my_gem/version.rb', target_patterns)).to be true
      end
    end

    context 'with non-Ruby files' do
      it 'returns false for non-Ruby files' do
        expect(described_class.should_include_file?('app/views/index.html.erb', target_patterns)).to be false
        expect(described_class.should_include_file?('config/application.yml', target_patterns)).to be false
        expect(described_class.should_include_file?('README.md', target_patterns)).to be false
      end
    end

    context 'with Ruby files not matching patterns' do
      it 'returns false for non-matching Ruby files' do
        expect(described_class.should_include_file?('spec/models/user_spec.rb', target_patterns)).to be false
        expect(described_class.should_include_file?('config/initializers/setup.rb', target_patterns)).to be false
      end
    end

    context 'with files without .rb extension' do
      it 'returns false even if path matches pattern structure' do
        expect(described_class.should_include_file?('app/models/user', target_patterns)).to be false
        expect(described_class.should_include_file?('lib/my_gem/version', target_patterns)).to be false
      end
    end
  end

  describe '.normalize_file_path' do
    let(:config) do
      instance_double(TestSentinel::Config,
                      directory_weights: [
                        { 'path' => 'app/**/*.rb', 'weight' => 1.0 },
                        { 'path' => 'lib/**/*.rb', 'weight' => 1.0 }
                      ])
    end

    before do
      allow(described_class).to receive(:load_config).and_return(config)
      allow(TestSentinel::PatternExpander).to receive(:extract_base_directories)
        .with(['app/**/*.rb', 'lib/**/*.rb'])
        .and_return(['app/', 'lib/'])
    end

    context 'with absolute paths containing base directories' do
      it 'normalizes absolute paths to relative paths from base directory' do
        result = described_class.normalize_file_path('/full/path/to/project/app/models/user.rb')
        expect(result).to eq('app/models/user.rb')
      end

      it 'handles lib directory paths' do
        result = described_class.normalize_file_path('/project/root/lib/my_gem/version.rb')
        expect(result).to eq('lib/my_gem/version.rb')
      end
    end

    context 'with already relative paths' do
      it 'returns relative paths as-is when they start with base directory' do
        result = described_class.normalize_file_path('app/models/user.rb')
        expect(result).to eq('app/models/user.rb')
      end

      it 'handles lib directory relative paths' do
        result = described_class.normalize_file_path('lib/my_gem/version.rb')
        expect(result).to eq('lib/my_gem/version.rb')
      end
    end

    context 'with paths not matching configured patterns' do
      it 'returns the file path as-is for flexible configuration' do
        unmatched_path = 'custom/directory/file.rb'
        result = described_class.normalize_file_path(unmatched_path)
        expect(result).to eq(unmatched_path)
      end
    end
  end

  describe '.load_config' do
    context 'when sentinel.yml exists' do
      let(:config_instance) { TestSentinel::Config.new }

      before do
        allow(File).to receive(:exist?).with('sentinel.yml').and_return(true)
        allow(TestSentinel::Config).to receive(:load).with('sentinel.yml').and_return(config_instance)
      end

      it 'loads configuration from the default config file' do
        result = described_class.load_config
        expect(result).to eq(config_instance)
        expect(TestSentinel::Config).to have_received(:load).with('sentinel.yml')
      end

      it 'calls Config.load with sentinel.yml path' do
        expect(TestSentinel::Config).to receive(:load).with('sentinel.yml').and_return(config_instance)
        described_class.load_config
      end
    end

    context 'when sentinel.yml does not exist' do
      let(:default_config) { TestSentinel::Config.new }

      before do
        allow(File).to receive(:exist?).with('sentinel.yml').and_return(false)
        allow(TestSentinel::Config).to receive(:new).and_return(default_config)
      end

      it 'returns a new Config instance with default values' do
        result = described_class.load_config
        expect(result).to eq(default_config)
        expect(TestSentinel::Config).to have_received(:new)
      end

      it 'calls Config.new for default configuration' do
        expect(TestSentinel::Config).to receive(:new).and_return(default_config)
        described_class.load_config
      end
    end

    context 'with default configuration structure' do
      before do
        allow(File).to receive(:exist?).with('sentinel.yml').and_return(false)
      end

      it 'provides directory_weights in the expected structure' do
        config = described_class.load_config
        expect(config.directory_weights).to be_an(Array)
        expect(config.directory_weights.first).to have_key('path')
        expect(config.directory_weights.first).to have_key('weight')
      end
    end
  end

  describe 'integration behavior' do
    context 'when methods work together' do
      before do
        allow(File).to receive(:exist?).with('sentinel.yml').and_return(false)
      end

      it 'demonstrates the complete workflow from config to file filtering' do
        # 1. Get patterns from config
        patterns = described_class.get_target_patterns

        # 2. Check if files should be included
        ruby_file = 'app/models/user.rb'
        non_ruby_file = 'app/views/index.html.erb'

        expect(described_class.should_include_file?(ruby_file, patterns)).to be true
        expect(described_class.should_include_file?(non_ruby_file, patterns)).to be false

        # 3. Normalize file paths
        absolute_path = '/project/root/app/models/user.rb'
        normalized = described_class.normalize_file_path(absolute_path)

        # The normalized path should be usable with patterns
        expect(described_class.should_include_file?(normalized, patterns)).to be true
      end
    end
  end
end
