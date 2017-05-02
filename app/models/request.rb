class Request < ApplicationRecord
  belongs_to :user
  enum status: [ :pending, :approved, :rejected, :cancelled ]
  validates :days, presence: true
  validates :status, numericality: true
end
