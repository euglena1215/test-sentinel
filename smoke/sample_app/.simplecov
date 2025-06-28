# frozen_string_literal: true

SimpleCov.start 'rails' do
  add_filter '/bin/'
  add_filter '/db/'
  add_filter '/test/'
  add_filter '/spec/'
  add_filter '/vendor/'
  add_filter '/config/'

  # Add packs directory to coverage
  add_group 'Packs', 'packs/'
end
