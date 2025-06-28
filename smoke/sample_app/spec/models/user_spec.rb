# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  let(:user) { User.new(name: 'Test User', email: 'test@example.com') }

  describe 'validations' do
    it 'is valid with valid attributes' do
      expect(user).to be_valid
    end

    it 'requires a name' do
      user.name = nil
      expect(user).not_to be_valid
    end

    it 'requires an email' do
      user.email = nil
      expect(user).not_to be_valid
    end
  end

  describe '#admin?' do
    it 'returns true when role is admin' do
      user.role = 'admin'
      expect(user.admin?).to be true
    end

    it 'returns false when role is not admin' do
      user.role = 'user'
      expect(user.admin?).to be false
    end
  end

  describe '#premium?' do
    it 'returns true when subscription_type is premium' do
      user.subscription_type = 'premium'
      expect(user.premium?).to be true
    end

    it 'returns false when subscription_type is not premium' do
      user.subscription_type = 'free'
      expect(user.premium?).to be false
    end
  end

  describe '#locked?' do
    it 'returns true when locked recently' do
      user.locked_at = 30.minutes.ago
      expect(user.locked?).to be true
    end

    it 'returns false when locked more than an hour ago' do
      user.locked_at = 2.hours.ago
      expect(user.locked?).to be false
    end
  end
end
