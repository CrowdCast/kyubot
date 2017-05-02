class KyuBot < SlackRubyBot::Bot
  help do
    title 'KyuBot'
    desc 'This bot manages days off requests.'

    command 'request' do
      desc 'Request one or multiple days off'
    end

    command 'cancel' do
      desc 'Cancel one or multiple days off'
    end

    command 'list' do
      desc 'List yourself. If you are an owner you can list a particular user or list all'
    end

    command 'set' do
      desc 'Set leave allowance for a user'
    end
  end

  command 'request' do |client, data, match|
    command_user = BotHelper.get_user(data.user)
    request_dates = BotHelper.get_dates(match['expression'])

    unless (command_user.all_days_requested & request_dates).empty?
      client.say(channel: data.channel, text: 'Sorry you have already requested 1 or more of those dates')
    end

    request = Request.create({
      user: command_user,
      days: request_dates,
      description: BotHelper.get_description(match['expression']),
    })
    request.send_to_approver

    client.say(channel: data.channel, text: 'Thanks! Your request has been made')
  end

  command 'cancel' do |client, data, match|
    command_user = BotHelper.get_user(data.user)
    cancel_dates = BotHelper.get_dates(match['expression'])
    canceled_dates = []

    client.say(channel: data.channel, text: "Sorry I don't understand.") unless cancel_dates

    # TO DO: much more efficient way of handling this because this current code makes me sad
    cancel_dates.each{|date|
      command_user.requests.each{|request|
        if request.days.include?(date)
          request.remove_date(date)
          canceled_dates.push(date)
        end
      }
    }

    if canceled_dates.empty?
      client.say(channel: data.channel, text: "No dates need to be canceled.")
    else
      client.say(channel: data.channel, text: "Canceled your requests.")
    end
  end

  # TO DO: make this more DRY
  command 'list' do |client, data, match|
    command_user = BotHelper.get_user(data.user)

    if match['expression'].nil?
      list_string = BotHelper.build_request_list_for_user(command_user)
      return client.say(channel: data.channel, text: list_string)
    end

    return client.say(channel: data.channel, text: 'Sorry you are not an approver.') unless command_user.is_approver

    set_user = User.find_by(slack_id: get_first_mention(match['expression']))

    if set_user
      list_string = BotHelper.build_request_list_for_user(set_user)
      return client.say(channel: data.channel, text: list_string)
    elsif match['expression'] === 'all'
      list_string = BotHelper.build_request_list_for_team(command_user.team)
      return client.say(channel: data.channel, text: list_string)
    end

    return client.say(channel: data.channel, text: "Sorry I don't understand.")

  end

  command 'set' do |client, data, match|
    command_user = BotHelper.get_user(data.user)
    return client.say(channel: data.channel, text: 'Sorry you are not an approver.') unless command_user.is_approver

    set_user = User.find_by(slack_id: BotHelper.get_first_mention(match['expression']))
    days = BotHelper.get_days(match['expression'])
    if set_user && days
      set_user.update({ allowance: days })
      client.say(channel: data.channel, text: "<@#{set_user.slack_id}> now has #{days} days allowance")
    else
      client.say(channel: data.channel, text: "Sorry I don't understand.")
    end
  end

  # TO DO: Remove these test commands below

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
end
