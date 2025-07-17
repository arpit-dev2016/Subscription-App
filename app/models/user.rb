class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }


  def subscription_active?
    subscription_status == "active" # Or use your actual logic/column
  end
end
