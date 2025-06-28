# frozen_string_literal: true

class PaymentService
  def initialize(user)
    @user = user
  end

  def calculate_fee(amount)
    base_fee = amount * 0.03

    if @user.premium?
      if @user.admin?
        base_fee * 0.5
      else
        base_fee * 0.8
      end
    elsif @user.active?
      if monthly_transaction_count >= 10
        base_fee * 1.2
      else
        base_fee
      end
    else
      raise PaymentError, 'Inactive users cannot process payments'
    end
  end

  def process_payment(amount, payment_method)
    return false if @user.locked?

    fee = calculate_fee(amount)
    total = amount + fee

    case payment_method
    when 'credit_card'
      process_credit_card_payment(total)
    when 'bank_transfer'
      process_bank_transfer(total)
    when 'paypal'
      process_paypal_payment(total)
    else
      raise ArgumentError, "Unsupported payment method: #{payment_method}"
    end
  end

  private

  def monthly_transaction_count
    # Simulate complex logic
    if @user.created_at > 1.month.ago
      rand(5..15)
    else
      rand(10..25)
    end
  end

  def process_credit_card_payment(amount)
    # Complex payment processing logic
    amount <= 10_000
  end

  def process_bank_transfer(amount)
    amount < 50_000
  end

  def process_paypal_payment(amount)
    @user.premium? && amount < 25_000
  end
end

class PaymentError < StandardError; end
