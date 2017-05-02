class Request < ApplicationRecord
  belongs_to :user

  enum status: [:pending, :approved, :rejected, :canceled]

  def start_date
    days.sort.first
  end

  def end_date
    days.sort.last
  end

  def duration
    days.length
  end

  def add_date(date)
    self.update({ days: days.push(date) }) unless days.include?(date)
  end

  def remove_date(date)
    self.update({ days: days - [date] })
    self.destroy if self.days.empty?
  end
  
  def send_to_approver
    # TO DO: Call Slack service to message approvers
  end
end
