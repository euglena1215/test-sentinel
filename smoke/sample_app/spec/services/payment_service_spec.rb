# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PaymentService do
  let(:user) { User.new(name: 'Test User', email: 'test@example.com', status: 'active') }
  let(:service) { PaymentService.new(user) }

  describe '#calculate_fee' do
    context 'when user is premium' do
      before { user.subscription_type = 'premium' }

      it 'applies premium discount' do
        fee = service.calculate_fee(1000)
        expect(fee).to eq(24.0) # 1000 * 0.03 * 0.8
      end

      context 'when user is admin' do
        before { user.role = 'admin' }

        it 'applies admin discount' do
          fee = service.calculate_fee(1000)
          expect(fee).to eq(15.0) # 1000 * 0.03 * 0.5
        end
      end
    end

    context 'when user is active but not premium' do
      it 'applies base fee' do
        allow(service).to receive(:monthly_transaction_count).and_return(5)
        fee = service.calculate_fee(1000)
        expect(fee).to eq(30.0) # 1000 * 0.03
      end
    end

    context 'when user is inactive' do
      before { user.status = 'inactive' }

      it 'raises PaymentError' do
        expect { service.calculate_fee(1000) }.to raise_error(PaymentError)
      end
    end
  end

  describe '#process_payment' do
    it 'returns false when user is locked' do
      user.locked_at = 30.minutes.ago
      result = service.process_payment(1000, 'credit_card')
      expect(result).to be false
    end
  end
end
