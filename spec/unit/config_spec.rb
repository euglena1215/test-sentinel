# frozen_string_literal: true

require 'spec_helper'
require 'test_sentinel/config'

RSpec.describe TestSentinel::Config do
  describe '#initialize' do
    context 'with directory_weights containing brace patterns' do
      let(:config_data) do
        {
          'directory_weights' => [
            { 'path' => '{app,packs/*}/models/**/*.rb', 'weight' => 2.0 },
            { 'path' => 'app/controllers/**/*.rb', 'weight' => 1.0 }
          ]
        }
      end

      subject { described_class.new(config_data) }

      it 'expands brace patterns into multiple entries' do
        expect(subject.directory_weights.count).to eq(3)
        expect(subject.directory_weights).to include(
          { 'path' => 'app/models/**/*.rb', 'weight' => 2.0 },
          { 'path' => 'packs/*/models/**/*.rb', 'weight' => 2.0 },
          { 'path' => 'app/controllers/**/*.rb', 'weight' => 1.0 }
        )
      end

      it 'correctly applies weights to expanded paths' do
        expect(subject.directory_weight_for('app/models/user.rb')).to eq(2.0)
        expect(subject.directory_weight_for('packs/users/models/user_profile.rb')).to eq(2.0)
        expect(subject.directory_weight_for('app/controllers/users_controller.rb')).to eq(1.0)
      end
    end

    context 'with default directory_weights' do
      subject { described_class.new }

      it 'does not expand default patterns' do
        expect(subject.directory_weights.count).to eq(4)
        expect(subject.directory_weights).to include(
          { 'path' => 'app/models/', 'weight' => 1.5 },
          { 'path' => 'app/services/', 'weight' => 1.5 },
          { 'path' => 'app/jobs/', 'weight' => 1.2 },
          { 'path' => 'app/controllers/', 'weight' => 1.0 }
        )
      end
    end
  end
end
