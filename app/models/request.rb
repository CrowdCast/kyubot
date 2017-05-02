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

  def duration_label
    return days.first if duration === 1
    "from #{start_date} to #{end_date}"
  end

  def add_date(date)
    self.update({ days: days.push(date) }) unless days.include?(date)
  end

  def remove_date(date)
    self.update({ days: days - [date] })
    self.destroy if self.days.empty?
  end
  
  def send_to_approver
    user.team.approvers.each do |approver|
      # next if approver == user
      puts "Send to approver #{approver.slack_name}"
      user.team.service_client.post_message({
        "channel": "@#{approver.slack_name}",
        "as_user": false,
        "text": "#{user.slack_name} has required to take #{duration_label} off.",
        "attachments": [{
          "text": "Do you approve this request?",
          "fallback": "You can't take a decision.",
          "callback_id": self.id,
          "color": "#3AA3E3",
          "attachment_type": "default",
          "actions": [
            {
              "name": "yes",
              "text": "Yes",
              "type": "button",
              "value": "yes",
            },
            {
              "name": "no",
              "text": "No",
              "type": "button",
              "value": "no",
            },
          ]
        }]
      })
    end
  end
end
