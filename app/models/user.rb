class User < ApplicationRecord
  belongs_to :team
  has_many :requests

  def days_remaining
    allowance - days_taken
  end

  def all_days_requested
    requests.map{|request| request.days}.flatten
  end
end
