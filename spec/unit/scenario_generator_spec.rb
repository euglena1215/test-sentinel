# frozen_string_literal: true

require 'spec_helper'
require 'test_sentinel/scenario_generator'
require 'tempfile'

RSpec.describe TestSentinel::ScenarioGenerator do
  describe '#extract_method_code' do
    let(:temp_file) { Tempfile.new(['test_file', '.rb']) }

    after { temp_file.unlink }

    context 'with a simple method' do
      let(:file_content) do
        <<~RUBY
          class User
            def calculate_discount(amount)
              if amount > 100
                amount * 0.1
              else
                0
              end
            end
          end
        RUBY
      end

      it 'extracts method code correctly' do
        temp_file.write(file_content)
        temp_file.rewind

        generator = described_class.new(temp_file.path, 'calculate_discount', 2)
        result = generator.send(:extract_method_code)

        expected_code = <<~RUBY
          def calculate_discount(amount)
              if amount > 100
                amount * 0.1
              else
                0
              end
        RUBY

        expect(result.strip).to eq(expected_code.strip)
      end
    end

    context 'with nested method structure' do
      let(:file_content) do
        <<~RUBY
          class PaymentService
            def process_payment(amount)
              validate_amount(amount)
          #{'    '}
              if amount > 1000
                apply_premium_processing(amount)
              else
                apply_standard_processing(amount)
              end
            end

            def validate_amount(amount)
              raise ArgumentError if amount <= 0
            end
          end
        RUBY
      end

      it 'extracts only the specified method' do
        temp_file.write(file_content)
        temp_file.rewind

        generator = described_class.new(temp_file.path, 'process_payment', 2)
        result = generator.send(:extract_method_code)

        expect(result).to include('def process_payment(amount)')
        expect(result).to include('validate_amount(amount)')
        expect(result).to include('apply_premium_processing(amount)')
        expect(result).not_to include('def validate_amount(amount)')
      end
    end

    context 'with method containing empty lines' do
      let(:file_content) do
        <<~RUBY
          class Calculator
            def complex_calculation(x, y)
              return 0 if x.nil? || y.nil?

              result = x * y

              result += 10 if result > 50

              result
            end
          end
        RUBY
      end

      it 'includes empty lines within the method' do
        temp_file.write(file_content)
        temp_file.rewind

        generator = described_class.new(temp_file.path, 'complex_calculation', 2)
        result = generator.send(:extract_method_code)

        expect(result).to include('def complex_calculation(x, y)')
        expect(result).to include('return 0 if x.nil? || y.nil?')
        expect(result).to include('result = x * y')
        expect(result.count("\n")).to be >= 6 # Should include empty lines
      end
    end

    context 'with method at different indentation levels' do
      let(:file_content) do
        <<~RUBY
          module TestModule
            class TestClass
              def instance_method
                puts "instance method"
              end

              private

              def private_method
                puts "private method"
              end
            end
          end
        RUBY
      end

      it 'extracts method with proper indentation detection' do
        temp_file.write(file_content)
        temp_file.rewind

        generator = described_class.new(temp_file.path, 'instance_method', 3)
        result = generator.send(:extract_method_code)

        expect(result).to include('def instance_method')
        expect(result).to include('puts "instance method"')
        expect(result).not_to include('private')
        expect(result).not_to include('def private_method')
      end
    end

    context 'with single line method' do
      let(:file_content) do
        <<~RUBY
          class Helper
            def simple_add(a, b); a + b; end
          end
        RUBY
      end

      it 'extracts single line method' do
        temp_file.write(file_content)
        temp_file.rewind

        generator = described_class.new(temp_file.path, 'simple_add', 2)
        result = generator.send(:extract_method_code)

        expect(result.strip).to eq('def simple_add(a, b); a + b; end')
      end
    end

    context 'with method containing case statement' do
      let(:file_content) do
        <<~RUBY
          class StatusHandler
            def handle_status(status)
              case status
              when 'active'
                activate_user
              when 'inactive'
                deactivate_user
              else
                handle_unknown_status
              end
            end
          end
        RUBY
      end

      it 'extracts method with case statement' do
        temp_file.write(file_content)
        temp_file.rewind

        generator = described_class.new(temp_file.path, 'handle_status', 2)
        result = generator.send(:extract_method_code)

        expect(result).to include('def handle_status(status)')
        expect(result).to include('case status')
        expect(result).to include("when 'active'")
        expect(result).to include("when 'inactive'")
        expect(result).to include('else')
      end
    end

    context 'with non-existent file' do
      it 'returns empty string' do
        generator = described_class.new('/non/existent/file.rb', 'method', 1)

        expect { generator.send(:extract_method_code) }.to raise_error(Errno::ENOENT)
      end
    end

    context 'with line number beyond file length' do
      let(:file_content) do
        <<~RUBY
          class Small
            def tiny_method
              puts "tiny"
            end
          end
        RUBY
      end

      it 'returns empty string when line number is too high' do
        temp_file.write(file_content)
        temp_file.rewind

        generator = described_class.new(temp_file.path, 'method', 100)
        result = generator.send(:extract_method_code)

        expect(result).to eq('')
      end
    end
  end
end
