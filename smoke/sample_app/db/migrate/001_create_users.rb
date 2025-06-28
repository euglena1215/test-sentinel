# frozen_string_literal: true

class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :email, null: false, index: { unique: true }
      t.integer :status, default: 0
      t.string :role, default: 'user'
      t.string :subscription_type, default: 'free'
      t.datetime :locked_at

      t.timestamps
    end
  end
end
