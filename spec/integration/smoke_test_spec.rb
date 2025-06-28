# frozen_string_literal: true

require 'spec_helper'
require 'json'
require 'yaml'
require 'tempfile'

RSpec.describe 'Smoke Test Integration' do
  SAMPLE_APP_DIR = File.expand_path('../../smoke/sample_app', __dir__)
  EXPECTED_OUTPUT_FILE = File.expand_path('../../expected_outputs/smoke_test_output.txt', __dir__)
  EXPECTED_JSON_FILE = File.expand_path('../../expected_outputs/smoke_test_analysis.json', __dir__)

  before(:all) do
    # Ensure sample app has coverage data
    Dir.chdir(SAMPLE_APP_DIR) do
      system('bundle exec rspec', out: File::NULL, err: File::NULL)
    end
  end

  describe 'CLI output consistency' do
    it 'produces expected console output format' do
      output = nil
      Dir.chdir(SAMPLE_APP_DIR) do
        output = `bundle exec test-sentinel generate --top-n 3 2>/dev/null`
      end

      expect(output).to include('🔍 Analyzing codebase...')
      expect(output).to include('📊 Top 3 methods requiring test coverage:')
      expect(output).to include('app/models/user.rb:19')
      expect(output).to include('Method: can_access_feature?')
      expect(output).to include('Priority Score:')
      expect(output).to include('Coverage:')
      expect(output).to include('Complexity:')
      expect(output).to include('Git Commits:')
      expect(output).to include('📄 Detailed analysis saved to test_sentinel_analysis.json')
    end

    it 'generates consistent JSON structure' do
      Dir.chdir(SAMPLE_APP_DIR) do
        system('bundle exec test-sentinel generate --top-n 5 2>/dev/null')
      end

      json_file = File.join(SAMPLE_APP_DIR, 'test_sentinel_analysis.json')
      expect(File.exist?(json_file)).to be true

      analysis = JSON.parse(File.read(json_file))

      expect(analysis).to be_an(Array)
      expect(analysis.length).to be >= 3

      # Check first result (highest priority)
      top_result = analysis.first
      expect(top_result).to include(
        'file_path' => 'app/models/user.rb',
        'method_name' => 'can_access_feature?',
        'line_number' => 19,
        'class_name' => 'User'
      )

      expect(top_result['score']).to be > 9.0
      expect(top_result['details']).to include('coverage', 'complexity', 'git_commits')
      expect(top_result['details']['complexity']).to eq(7)
    end
  end

  describe 'score calculation consistency' do
    it 'maintains consistent priority scoring' do
      Dir.chdir(SAMPLE_APP_DIR) do
        system('bundle exec test-sentinel generate --top-n 10 2>/dev/null')
      end

      json_file = File.join(SAMPLE_APP_DIR, 'test_sentinel_analysis.json')
      analysis = JSON.parse(File.read(json_file))

      # Verify scores are in descending order
      scores = analysis.map { |item| item['score'] }
      expect(scores).to eq(scores.sort.reverse)

      # Verify expected top methods
      top_3_methods = analysis.first(3).map { |item| "#{item['file_path']}:#{item['method_name']}" }
      expect(top_3_methods).to include('app/models/user.rb:can_access_feature?')
      expect(top_3_methods).to include('app/services/payment_service.rb:calculate_fee')
      expect(top_3_methods).to include('app/services/payment_service.rb:process_payment')
    end

    it 'correctly weights complexity vs coverage' do
      Dir.chdir(SAMPLE_APP_DIR) do
        system('bundle exec test-sentinel generate --top-n 10 2>/dev/null')
      end

      json_file = File.join(SAMPLE_APP_DIR, 'test_sentinel_analysis.json')
      analysis = JSON.parse(File.read(json_file))

      # Find the can_access_feature? method (highest complexity)
      can_access_feature = analysis.find { |item| item['method_name'] == 'can_access_feature?' }
      expect(can_access_feature).not_to be_nil
      expect(can_access_feature['details']['complexity']).to eq(7)

      # Find a calculate_fee method (medium complexity)
      calculate_fee = analysis.find { |item| item['method_name'] == 'calculate_fee' }
      expect(calculate_fee).not_to be_nil
      expect(calculate_fee['details']['complexity']).to eq(5)

      # Higher complexity method should have higher score (given similar coverage)
      expect(can_access_feature['score']).to be > calculate_fee['score']
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

  describe 'error handling' do
    it 'handles missing coverage data gracefully' do
      Dir.chdir(SAMPLE_APP_DIR) do
        # Temporarily move coverage directory
        FileUtils.mv('coverage', 'coverage_backup') if Dir.exist?('coverage')

        output = `bundle exec test-sentinel generate --top-n 3 2>/dev/null`

        # Should still work, just with different scores
        expect(output).to include('🔍 Analyzing codebase...')
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
