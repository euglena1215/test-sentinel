# frozen_string_literal: true

require 'spec_helper'
require 'code_qualia/config'

RSpec.describe CodeQualia::Config do
  describe '#initialize' do
    context 'with architectural_weights containing brace patterns' do
      let(:config_data) do
        {
          'architectural_weights' => [
            { 'path' => '{app,packs/*}/models/**/*.rb', 'weight' => 2.0 },
            { 'path' => 'app/controllers/**/*.rb', 'weight' => 1.0 }
          ]
        }
      end

      subject { described_class.new(config_data) }

      it 'expands brace patterns into multiple entries' do
        expect(subject.architectural_weights.count).to eq(3)
        expect(subject.architectural_weights).to include(
          { 'path' => 'app/models/**/*.rb', 'weight' => 2.0 },
          { 'path' => 'packs/*/models/**/*.rb', 'weight' => 2.0 },
          { 'path' => 'app/controllers/**/*.rb', 'weight' => 1.0 }
        )
      end

      it 'correctly applies weights to expanded paths' do
        expect(subject.architectural_weight_for('app/models/user.rb')).to eq(2.0)
        expect(subject.architectural_weight_for('packs/users/models/user_profile.rb')).to eq(2.0)
        expect(subject.architectural_weight_for('app/controllers/users_controller.rb')).to eq(1.0)
      end
    end

    context 'with default architectural_weights' do
      subject { described_class.new }

      it 'does not expand default patterns' do
        expect(subject.architectural_weights.count).to eq(1)
        expect(subject.architectural_weights).to eq([{ 'path' => '**/*.rb', 'weight' => 1.0 }])
      end
    end
  end
end
