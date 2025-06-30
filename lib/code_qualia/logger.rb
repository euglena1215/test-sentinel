# frozen_string_literal: true

module CodeQualia
  class Logger
    class << self
      attr_accessor :verbose

      def log(message)
        return unless verbose

        timestamp = Time.now.strftime('%H:%M:%S')
        $stderr.puts "[#{timestamp}] #{message}"
      end

      def log_step(step_name)
        return unless verbose

        timestamp = Time.now.strftime('%H:%M:%S')
        $stderr.puts "[#{timestamp}] 🔍 Starting #{step_name}..."
      end

      def log_result(step_name, result_count = nil, duration = nil)
        return unless verbose

        timestamp = Time.now.strftime('%H:%M:%S')
        message = "[#{timestamp}] ✅ #{step_name} completed"
        message += " (#{result_count} items)" if result_count
        message += " in #{duration.round(2)}s" if duration
        $stderr.puts message
      end

      def log_error(step_name, error)
        return unless verbose

        timestamp = Time.now.strftime('%H:%M:%S')
        $stderr.puts "[#{timestamp}] ❌ #{step_name} failed: #{error.message}"
      end

      def log_skip(step_name, reason)
        return unless verbose

        timestamp = Time.now.strftime('%H:%M:%S')
        $stderr.puts "[#{timestamp}] ⏭️  Skipping #{step_name}: #{reason}"
      end
    end
  end
end