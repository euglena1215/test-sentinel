# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Smoke Test Integration' do
  SMOKE_DIR = File.expand_path('../../smoke', __dir__)
  EXPECTED_OUTPUTS_DIR = File.expand_path('../../expected_outputs', __dir__)

  # Auto-detect projects in smoke directory that have expected outputs
  def self.smoke_projects
    @smoke_projects ||= begin
      projects = []
      Dir.entries(SMOKE_DIR).each do |entry|
        project_path = File.join(SMOKE_DIR, entry)
        expected_path = File.join(EXPECTED_OUTPUTS_DIR, entry)

        # Only include directories that have a Gemfile and expected outputs
        next unless File.directory?(project_path) &&
                    !entry.start_with?('.') &&
                    File.exist?(File.join(project_path, 'Gemfile')) &&
                    File.directory?(expected_path)

        projects << {
          name: entry,
          dir: project_path,
          expected_path: expected_path,
          is_rails: File.exist?(File.join(project_path, 'config', 'application.rb'))
        }
      end
      projects
    end
  end

  # Generate tests for each detected smoke project
  smoke_projects.each do |project|
    describe "smoke test for #{project[:name]}" do
      before do
        # Generate coverage data for all projects (unless in CI where it's pre-generated)
        unless ENV['CI']
          Dir.chdir(project[:dir]) do
            if File.exist?('spec/spec_helper.rb')
              `bundle exec rspec --require spec_helper 2>/dev/null || true`
            elsif File.exist?('test/test_helper.rb')
              `bundle exec rake test 2>/dev/null || true`
            end
          end
        end
      end

      after do
        # Clean up generated files
        generated_json_path = File.join(project[:dir], 'code_qualia_analysis.json')
        File.delete(generated_json_path) if File.exist?(generated_json_path)
      end

      %w[human json csv table].each do |format|
        it "produces expected #{format} format output" do
          command_output = if project[:is_rails]
            # For Rails projects, run from within the project directory
            `cd #{project[:dir]} && bundle exec code-qualia generate --format #{format} --top-n 10 2>/dev/null`
          else
            # For non-Rails projects, run from project root with --directory option
            `bundle exec code-qualia generate --format #{format} --directory #{project[:dir]} --top-n 10 2>/dev/null`
          end

          expected_file_extension = format == 'json' ? 'json' : (format == 'csv' ? 'csv' : 'txt')
          expected_file = File.join(project[:expected_path], "output_#{format}.#{expected_file_extension}")
          
          expect(File.exist?(expected_file)).to be(true)
          
          expected_output = File.read(expected_file)
          expect(command_output).to eq(expected_output)
        end
      end

    end
  end
end
