class Subscription < ApplicationRecord
  belongs_to :user
  attr_accessor :current_period_end
end
