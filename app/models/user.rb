class User < ApplicationRecord
  has_many :requests
  validates :slack_id, :slack_name, presence: true
  validates :is_approver, inclusion: { in: [true, false] }
  validates :allowance, numericality: true
  validates :days_taken, numericality: true
end
