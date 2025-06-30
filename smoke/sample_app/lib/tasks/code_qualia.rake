# frozen_string_literal: true

namespace :code_qualia do
  desc 'Analyze codebase and generate test recommendations'
  task :analyze, [:top_n] => :environment do |_t, args|
    top_n = args[:top_n] || 5
    puts "🔍 Running Code Qualia analysis (top #{top_n} methods)..."

    system("bundle exec code-qualia generate --top-n #{top_n}")
  end

  desc 'Generate test recommendations for top 10 methods'
  task full_analysis: :environment do
    puts '🔍 Running full Code Qualia analysis...'
    system('bundle exec code-qualia generate --top-n 10')
  end
end
