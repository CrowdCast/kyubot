class KyuBot < SlackRubyBot::Bot
  help do
    title 'KyuBot'
    desc 'This bot manages days off requests.'

    command 'request' do
      desc 'Request one or multiple days off'
    end
  end

  command 'say' do |client, data, match|
    client.say(channel: data.channel, text: match['expression'])
  end

  command 'ping' do |client, data, match|
    client.say(text: 'pong', channel: data.channel)
  end

  command 'ask' do |client, data, match|
    client = Slack::Web::Client.new
    client.chat_postMessage(
      channel: data.channel,
      as_user: true,
      text: 'Do you like cheese?',
      attachments: [{
        "text": "Choose your cheese level",
        "fallback": "You are unable to eat cheese",
        "callback_id": "cheese_question",
        "color": "#3AA3E3",
        "attachment_type": "default",
        "actions": [
          {
            "name": "cheese",
            "text": "Yes",
            "type": "button",
            "value": "yes"
          },
          {
            "name": "cheese",
            "text": "No",
            "type": "button",
            "value": "no"
          },
          {
            "name": "cheese",
            "text": "Only stinky ones",
            "type": "button",
            "value": "stinky"
          },
          {
            "name": "cheese",
            "text": "I am French",
            "style": "danger",
            "type": "button",
            "value": "french",
            "confirm": {
              "title": "Are you sure?",
              "text": "Wouldn't you prefer a good American processed cheese?",
              "ok_text": "Yes",
              "dismiss_text": "No"
            }
          }
        ]
      }]
    )
  end

  private
    def get_user(slack_id)
      User.find_by(slack_id: slack_id)
    end

    def get_team(slack_id)
      Team.find_by(slack_id: slack_id)
    end

    def get_first_mention(expression)
      return string[/<@(.*?)>/m, 1]
    end

    def get_days(expression)
      get_expression_without_mentions(expression)[/\d+/]
    end

    def get_dates(expression)
      # set strings to be lowercase
      string = expression.downcase

      dates = []

      # from <YYYY/MM/DD>
      if string.match(/from\s+((\d\d\d\d\/)?\d?\d\/\d?\d)/)
        date_from = Date.parse(string.match(/from\s+((\d\d\d\d\/)?\d?\d\/\d?\d)/)[1])
      end

      # today
      if string.match(/today/)
        date_from = Date.today
      end

      # to <YYYY/MM/DD>
      if string.match(/to\s+((\d\d\d\d\/)?\d?\d\/\d?\d)/)
        date_to = Date.parse(string.match(/to\s+((\d\d\d\d\/)?\d?\d\/\d?\d)/)[1])

        (date_to - date_from).to_i.times do |x| dates << date_from+x end
        dates << date_to
        return dates
      end

      # days from
      if string.match(/(\d)+\s+days/)
        # since index is zero indexed
        index = string.match(/(\d)+\s+days/)[1].to_i
        index.times do |x| dates << date_from+x end
        return dates
      end

      # Single date entry
      # Parse date, date format is [YYYY/]?M?M/D?D
      return [Date.parse(string.match(/((\d\d\d\d\/)?\d?\d\/\d?\d)$/)[1])]
    end

    def get_description(expression)
      # Regex to get description text from a days off requesst
      non_description = expression.match(/(.*\sfor\s)/)[1]
      expression.gsub(non_description, '')
    end

    def get_expression_without_mentions(expression)
      # Regex to remove out mentions <@FOO> from expression
      user = expression.match(/(<@.*>)/)[1]
      expression.gsub(user,'')
    end

    def build_request_list_for_user(user)
      if user.requests.any?
        # TO DO: Build a message with all the user requests
      else
        return "<@#{user.slack_id}> has no requests"
      end
    end

    def build_request_list_for_team(team)
      list_string = ""
      team.users.each {|user|
        list_string << "\n#{build_request_list_for_user(user)}"
      }
      return list_string
    end
end