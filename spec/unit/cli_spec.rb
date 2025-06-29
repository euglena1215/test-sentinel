# frozen_string_literal: true

require 'spec_helper'
require 'test_sentinel'

RSpec.describe TestSentinel::CLI do
  let(:cli) { described_class.new(argv) }

  describe '#initialize' do
    let(:argv) { [] }

    it 'sets default options' do
      cli = described_class.new(argv)
      options = cli.instance_variable_get(:@options)
      
      expect(options[:top_n]).to eq(3)
      expect(options[:config]).to eq('./sentinel.yml')
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

    context 'with invalid format' do
      let(:argv) { ['generate', '--format', 'invalid'] }

      it 'exits with error message' do
        expect { cli.send(:parse_options) }.to output(/Error: Invalid format/).to_stdout.and raise_error(SystemExit)
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
end