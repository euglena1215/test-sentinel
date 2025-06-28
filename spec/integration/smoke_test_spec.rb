# frozen_string_literal: true

require 'spec_helper'
require 'json'
require 'yaml'
require 'tempfile'

RSpec.describe 'Smoke Test Integration' do
  SAMPLE_APP_DIR = File.expand_path('../../smoke/sample_app', __dir__)
  EXPECTED_OUTPUT_FILE = File.expand_path('../../expected_outputs/smoke_test_output.txt', __dir__)
  EXPECTED_JSON_FILE = File.expand_path('../../expected_outputs/smoke_test_analysis.json', __dir__)

  describe 'CLI output consistency' do
    let(:command_output) do
      Dir.chdir(SAMPLE_APP_DIR) do
        `bundle exec test-sentinel generate --top-n 10 2>/dev/null`
      end
    end

    let(:generated_json_path) { File.join(SAMPLE_APP_DIR, 'test_sentinel_analysis.json') }
    let(:generated_json) { JSON.parse(File.read(generated_json_path)) }
    let(:expected_json) { JSON.parse(File.read(EXPECTED_JSON_FILE)) }

    before do
      # Run the command to generate output files for each test
      command_output
    end

    it 'produces expected console output' do
      # Replace the absolute path with a placeholder for consistent comparison
      normalized_output = command_output.gsub(/Analyzing codebase in .*sample_app(\/|\.\.\.)?/,
                                              'Analyzing codebase in ./smoke/sample_app...')
      expected_output = File.read(EXPECTED_OUTPUT_FILE).gsub(/Analyzing codebase in .*sample_app(\/|\.\.\.)?/,
                                              'Analyzing codebase in ./smoke/sample_app...')

      expect(normalized_output).to eq(expected_output)
    end

    it 'generates a JSON file with the expected content' do
      expect(File.exist?(generated_json_path)).to be true
      expect(generated_json).to eq(expected_json)
    end

    it 'maintains consistent priority scoring' do
      # This is implicitly tested by the full JSON comparison,
      # but an explicit check remains useful for clarity.
      scores = generated_json.map { |item| item['score'] }
      expect(scores).to eq(scores.sort.reverse)
    end
  end

  describe 'configuration handling' do
    it 'respects custom configuration' do
      config_content = {
        'score_weights' => {
          'coverage' => 2.0,
          'complexity' => 0.5,
          'git_history' => 0.1,
          'directory' => 1.0
        },
        'exclude' => ['app/controllers/**/*']
      }

      Tempfile.create(['custom_sentinel', '.yml']) do |config_file|
        config_file.write(YAML.dump(config_content))
        config_file.flush

        output = nil
        Dir.chdir(SAMPLE_APP_DIR) do
          output = `bundle exec test-sentinel generate --config #{config_file.path} --top-n 5 2>/dev/null`
        end

        expect(output).to include('📊 Top 5 methods requiring test coverage:')
        # With controllers excluded, should not see any controller methods
        expect(output).not_to include('app/controllers/')
      end
    end
  end

  describe 'configuration handling' do
    it 'respects custom configuration' do
      config_content = {
        'score_weights' => {
          'coverage' => 2.0,
          'complexity' => 0.5,
          'git_history' => 0.1,
          'directory' => 1.0
        },
        'exclude' => ['app/controllers/**/*']
      }

      Tempfile.create(['custom_sentinel', '.yml']) do |config_file|
        config_file.write(YAML.dump(config_content))
        config_file.flush

        output = nil
        Dir.chdir(SAMPLE_APP_DIR) do
          output = `bundle exec test-sentinel generate --config #{config_file.path} --top-n 5 2>/dev/null`
        end

        expect(output).to include('📊 Top 5 methods requiring test coverage:')
        # With controllers excluded, should not see any controller methods
        expect(output).not_to include('app/controllers/')
      end
    end

    it 'applies wildcard directory weights correctly' do
      config_content = {
        'directory_weights' => [
          { 'path' => 'packs/**/*.rb', 'weight' => 2.5 }, # Add weight for packs
          { 'path' => 'app/models/**/*.rb', 'weight' => 2.0 },
          { 'path' => 'app/controllers/**/*.rb', 'weight' => 1.5 },
          { 'path' => 'app/**/*.rb', 'weight' => 1.0 }
        ]
      }

      Tempfile.create(['wildcard_sentinel', '.yml']) do |config_file|
        config_file.write(YAML.dump(config_content))
        config_file.flush

        generated_json_path = File.join(SAMPLE_APP_DIR, 'test_sentinel_analysis.json')
        Dir.chdir(SAMPLE_APP_DIR) do
          `bundle exec test-sentinel generate --config #{config_file.path} --top-n 10 2>/dev/null`
        end

        generated_json = JSON.parse(File.read(generated_json_path))

        user_model_method = generated_json.find do |m|
          m['file_path'] == 'app/models/user.rb' && m['method_name'] == 'can_access_feature?'
        end
        users_controller_method = generated_json.find do |m|
          m['file_path'] == 'app/controllers/users_controller.rb' && m['method_name'] == 'index'
        end
        packs_user_profile_method = generated_json.find do |m|
          m['file_path'] == 'packs/users/app/models/users/user_profile.rb' && m['method_name'] == 'display_name'
        end

        expect(user_model_method).not_to be_nil
        expect(users_controller_method).not_to be_nil
        expect(packs_user_profile_method).not_to be_nil

        # Verify that the correct directory weights are applied
        config_instance = TestSentinel::Config.new(config_content)
        expect(config_instance.directory_weight_for('packs/users/app/models/users/user_profile.rb')).to eq(2.5)
        expect(config_instance.directory_weight_for('app/models/user.rb')).to eq(2.0)
        expect(config_instance.directory_weight_for('app/controllers/users_controller.rb')).to eq(1.5)
      end
    end
  end

  describe 'error handling' do
    it 'handles missing coverage data gracefully' do
      Dir.chdir(SAMPLE_APP_DIR) do
        # Temporarily move coverage directory
        FileUtils.mv('coverage', 'coverage_backup') if Dir.exist?('coverage')

        output = `bundle exec test-sentinel generate --top-n 3 2>/dev/null`

        # Should still work, just with different scores
        expect(output).to include('🔍 Analyzing codebase')
        expect(output).to include('📊 Top 3 methods requiring test coverage:')

        # Restore coverage data
        FileUtils.mv('coverage_backup', 'coverage') if Dir.exist?('coverage_backup')
      end
    end

    it 'handles missing rubocop gracefully' do
      # Test would require temporarily renaming rubocop, skipping for now
      skip 'Requires complex environment manipulation'
    end
  end
end
