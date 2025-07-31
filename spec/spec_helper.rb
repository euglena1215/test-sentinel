# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
  add_filter '/smoke/'
end

require 'bundler/setup'
require 'code_qualia'
require 'rspec'
require 'yaml'
require 'fileutils'

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.filter_run_when_matching :focus

  config.disable_monkey_patching!

  config.warnings = true

  config.default_formatter = 'doc' if config.files_to_run.one?

  config.profile_examples = 10

  config.order = :random

  Kernel.srand config.seed

  config.around do |example|
    example.run
  rescue SystemExit => e
    # テストでSystemExitが発生した場合の処理
    raise "Test called exit(#{e.status}) - use allow_exit: true if intentional" unless example.metadata[:allow_exit]

    # 許可されたテストの場合はSystemExitを再発生させない
    # 代わりにテストが正常終了したものとして扱う
    nil
  end
end
