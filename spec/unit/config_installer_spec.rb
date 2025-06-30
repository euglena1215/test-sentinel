# frozen_string_literal: true

require 'spec_helper'
require 'code_qualia/config_installer'
require 'tmpdir'

RSpec.describe CodeQualia::ConfigInstaller do
  let(:temp_dir) { File.join(Dir.tmpdir, 'code-qualia-spec') }
  let(:installer) { described_class.new(temp_dir) }

  before do
    FileUtils.mkdir_p(temp_dir)
  end

  after do
    FileUtils.rm_rf(temp_dir) if Dir.exist?(temp_dir)
  end

  describe '#install' do
    context 'when qualia.yml does not exist' do
      it 'creates a configuration file' do
        expect { installer.install }.to output(/Configuration file 'qualia.yml' created successfully!/).to_stdout

        config_path = File.join(temp_dir, 'qualia.yml')
        expect(File.exist?(config_path)).to be true
      end

      context 'when Rails project is detected' do
        before do
          gemfile_path = File.join(temp_dir, 'Gemfile')
          app_dir = File.join(temp_dir, 'app')

          File.write(gemfile_path, 'gem "rails"')
          FileUtils.mkdir_p(app_dir)
        end

        it 'generates Rails-specific configuration' do
          expect { installer.install }.to output(/Detected project type: Rails application/).to_stdout

          config_path = File.join(temp_dir, 'qualia.yml')
          config_content = File.read(config_path)

          expect(config_content).to include('app/models/**/*.rb')
          expect(config_content).to include('app/controllers/**/*.rb')
          expect(config_content).to include('app/views/**/*')
        end
      end

      context 'when Ruby gem is detected' do
        before do
          gemspec_path = File.join(temp_dir, 'test.gemspec')
          lib_dir = File.join(temp_dir, 'lib')

          File.write(gemspec_path, 'dummy gemspec')
          FileUtils.mkdir_p(lib_dir)
        end

        it 'generates gem-specific configuration' do
          expect { installer.install }.to output(/Detected project type: Ruby gem/).to_stdout

          config_path = File.join(temp_dir, 'qualia.yml')
          config_content = File.read(config_path)

          expect(config_content).to include('lib/**/*.rb')
          expect(config_content).to include('bin/**/*')
          expect(config_content).to include('Gemfile*')
        end
      end

      context 'when neither Rails nor gem is detected' do
        it 'generates default configuration' do
          expect { installer.install }.to output(/Detected project type: Ruby project/).to_stdout

          config_path = File.join(temp_dir, 'qualia.yml')
          config_content = File.read(config_path)

          expect(config_content).to include('app/**/*.rb')
          expect(config_content).to include('lib/**/*.rb')
        end
      end
    end

    context 'when qualia.yml already exists' do
      before do
        config_path = File.join(temp_dir, 'qualia.yml')
        File.write(config_path, 'existing config')
      end

      it 'does not overwrite the existing file' do
        expect { installer.install }.to output(/Configuration file 'qualia.yml' already exists/).to_stdout

        config_path = File.join(temp_dir, 'qualia.yml')
        expect(File.read(config_path)).to eq('existing config')
      end
    end
  end
end
