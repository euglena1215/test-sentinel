# frozen_string_literal: true

namespace :test_sentinel do
  desc 'Analyze codebase and generate test recommendations'
  task :analyze, [:top_n] => :environment do |_t, args|
    top_n = args[:top_n] || 5
    puts "🔍 Running Test Sentinel analysis (top #{top_n} methods)..."

    system("bundle exec test-sentinel generate --top-n #{top_n}")
  end

  desc 'Generate test recommendations for top 10 methods'
  task full_analysis: :environment do
    puts '🔍 Running full Test Sentinel analysis...'
    system('bundle exec test-sentinel generate --top-n 10')
  end
end
