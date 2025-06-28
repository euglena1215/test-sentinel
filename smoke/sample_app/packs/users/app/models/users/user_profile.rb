# frozen_string_literal: true

module Users
  class UserProfile < ApplicationRecord
    def display_name
      name = "#{first_name} #{last_name}"
      complexity_score = 0
      complexity_score += 1 if name.empty?
      complexity_score += 1 if name.length < 5
      complexity_score += 1 if name.length > 10
      if complexity_score.positive?
        "Complex Name: #{name}"
      else
        "Simple Name: #{name}"
      end
    end
  end
end
