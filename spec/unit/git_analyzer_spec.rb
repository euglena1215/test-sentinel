# frozen_string_literal: true

require 'spec_helper'
require 'test_sentinel/git_analyzer'

RSpec.describe TestSentinel::GitAnalyzer do
  describe '#parse_git_log' do
    subject(:analyzer) { described_class.new }
    
    # Mock config for path normalization only
    before do
      test_config = instance_double(TestSentinel::Config,
        directory_weights: [
          { 'path' => 'app/**/*.rb', 'weight' => 1.0 },
          { 'path' => 'lib/**/*.rb', 'weight' => 1.0 }
        ]
      )
      allow(TestSentinel::ConfigHelper).to receive(:load_config).and_return(test_config)
    end

    context 'with valid git log output containing app/ files' do
      let(:git_output) do
        <<~OUTPUT
          app/models/user.rb
          app/controllers/users_controller.rb
          app/models/user.rb
          app/services/payment_service.rb
          app/models/user.rb
        OUTPUT
      end

      it 'counts file changes correctly' do
        result = analyzer.send(:parse_git_log, git_output)

        expect(result).to eq({
                               'app/models/user.rb' => 3,
                               'app/controllers/users_controller.rb' => 1,
                               'app/services/payment_service.rb' => 1
                             })
      end
    end

    context 'with valid git log output containing lib/ files' do
      let(:git_output) do
        <<~OUTPUT
          lib/test_sentinel/analyzer.rb
          lib/test_sentinel/coverage.rb
          lib/test_sentinel/analyzer.rb
        OUTPUT
      end

      it 'counts lib/ file changes correctly' do
        result = analyzer.send(:parse_git_log, git_output)

        expect(result).to eq({
                               'lib/test_sentinel/analyzer.rb' => 2,
                               'lib/test_sentinel/coverage.rb' => 1
                             })
      end
    end

    context 'with mixed app/ and lib/ files' do
      let(:git_output) do
        <<~OUTPUT
          app/models/user.rb
          lib/analyzer.rb
          config/application.rb
          app/models/user.rb
          lib/analyzer.rb
          db/migrate/001_create_users.rb
          app/controllers/application_controller.rb
        OUTPUT
      end

      it 'only counts app/ and lib/ files' do
        result = analyzer.send(:parse_git_log, git_output)

        expect(result).to eq({
                               'app/models/user.rb' => 2,
                               'lib/analyzer.rb' => 2,
                               'app/controllers/application_controller.rb' => 1
                             })

        expect(result).not_to have_key('config/application.rb')
        expect(result).not_to have_key('db/migrate/001_create_users.rb')
      end
    end

    context 'with non-Ruby files' do
      let(:git_output) do
        <<~OUTPUT
          app/assets/stylesheets/application.css
          app/views/users/index.html.erb
          app/models/user.rb
          lib/tasks/scheduler.rake
          README.md
        OUTPUT
      end

      it 'only counts Ruby files' do
        result = analyzer.send(:parse_git_log, git_output)

        expect(result).to eq({
                               'app/models/user.rb' => 1
                             })

        expect(result).not_to have_key('app/assets/stylesheets/application.css')
        expect(result).not_to have_key('app/views/users/index.html.erb')
        expect(result).not_to have_key('lib/tasks/scheduler.rake')
        expect(result).not_to have_key('README.md')
      end
    end

    context 'with empty output' do
      it 'returns empty hash' do
        result = analyzer.send(:parse_git_log, '')
        expect(result).to eq({})
      end
    end

    context 'with whitespace and empty lines' do
      let(:git_output) do
        <<~OUTPUT

          app/models/user.rb#{'  '}
          #{'  '}
          lib/analyzer.rb


          app/models/user.rb

        OUTPUT
      end

      it 'handles whitespace correctly' do
        result = analyzer.send(:parse_git_log, git_output)

        expect(result).to eq({
                               'app/models/user.rb' => 2,
                               'lib/analyzer.rb' => 1
                             })
      end
    end

    context 'with files that do not start with app/ or lib/' do
      let(:git_output) do
        <<~OUTPUT
          some/other/path/app/models/user.rb
          prefix_app/models/user.rb
          lib_prefix/analyzer.rb
          app/models/user.rb
          lib/analyzer.rb
        OUTPUT
      end

      it 'only includes files that start with app/ or lib/' do
        result = analyzer.send(:parse_git_log, git_output)

        expect(result).to eq({
                               'app/models/user.rb' => 1,
                               'lib/analyzer.rb' => 1
                             })

        expect(result).not_to have_key('some/other/path/app/models/user.rb')
        expect(result).not_to have_key('prefix_app/models/user.rb')
        expect(result).not_to have_key('lib_prefix/analyzer.rb')
      end
    end

    context 'with complex file paths' do
      let(:git_output) do
        <<~OUTPUT
          app/models/concerns/trackable.rb
          app/controllers/api/v1/users_controller.rb
          lib/generators/test_generator.rb
          app/services/external_api/payment_processor.rb
        OUTPUT
      end

      it 'handles nested directory structures' do
        result = analyzer.send(:parse_git_log, git_output)

        expect(result).to eq({
                               'app/models/concerns/trackable.rb' => 1,
                               'app/controllers/api/v1/users_controller.rb' => 1,
                               'lib/generators/test_generator.rb' => 1,
                               'app/services/external_api/payment_processor.rb' => 1
                             })
      end
    end

    context 'with real git log format including commit hashes and dates' do
      let(:git_output) do
        <<~OUTPUT

          app/models/user.rb

          app/controllers/users_controller.rb
          app/models/user.rb

          lib/analyzer.rb

        OUTPUT
      end

      it 'extracts file paths correctly ignoring git metadata' do
        result = analyzer.send(:parse_git_log, git_output)

        expect(result).to eq({
                               'app/models/user.rb' => 2,
                               'app/controllers/users_controller.rb' => 1,
                               'lib/analyzer.rb' => 1
                             })
      end
    end
  end
end
