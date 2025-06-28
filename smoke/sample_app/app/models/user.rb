# frozen_string_literal: true

class User < ApplicationRecord
  validates :email, presence: true, uniqueness: true
  validates :name, presence: true

  enum :status, { active: 0, inactive: 1, suspended: 2 }

  def admin?
    role == 'admin'
  end

  def premium?
    subscription_type == 'premium'
  end

  def locked?
    locked_at.present? && locked_at > 1.hour.ago
  end

  def can_access_feature?(feature_name)
    return false if inactive? || suspended?
    return true if admin?

    case feature_name
    when 'analytics'
      premium?
    when 'export'
      premium? || active?
    else
      active?
    end
  end

  def calculate_discount
    return 0.0 unless premium?

    if admin?
      0.25
    elsif created_at < 1.year.ago
      0.15
    else
      0.10
    end
  end
end
