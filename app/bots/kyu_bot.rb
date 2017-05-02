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

  command 'request' do |client, data, match|
    dateArray = parseDate(match['expression'])
    # Request.new(client.name)
  end

  command 'cancel' do |client, data, match|
  end

  command 'input' do |client, data, match|
  end

  command 'list' do |client, data, match|
    if match['expression']
      requestedUser = getUserId(match['expression'])
      requestingUser = getUserId(data.user)

      # client.say(text: user.allowance)
      # client.say(text: 'theres nothing to list', channel: data.channel)
    else
      # team = Team.find(team_id: data.teamId)

      #  users.each { |user| client.say(text: 'username') }

      client.say(text: 'listen to my hearttt', channel: data.channel)
    end
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

  def getUserId(user)
    userId = match['expression'].delete("<@>")
    return User.where(slack_id: userId)
  end

  def parseDate(string)
    # set strings to be lowercase
    string.downcase

    dateArray = []

    # from <YYYY/MM/DD>
    if string.match(/^from\s+((\d\d\d\d\/)?\d?\d\/\d?\d)/)
      fromDate = Date.parse(string.match(/^from\s+((\d\d\d\d\/)?\d?\d\/\d?\d)/)[1])
    end

    # today
    if string.match(/today/)
      fromDate = Date.today
    end

    # to <YYYY/MM/DD>
    if string.match(/to\s+((\d\d\d\d\/)?\d?\d\/\d?\d)/)
      toDate = Date.parse(string.match(/to\s+((\d\d\d\d\/)?\d?\d\/\d?\d)/)[1])

      (toDate - fromDate).to_i.times do |x| dateArray << fromDate+x end
      dateArray << toDate
      return dateArray
    end

    # days from
    if string.match(/(\d)+\s+days/)
      # since index is zero indexed
      index = string.match(/(\d)+\s+days/)[1].to_i
      index.times do |x| dateArray << fromDate+x end
      return dateArray
    end

    # Single date entry
    # Parse date, date format is [YYYY/]?M?M/D?D
    return [Date.parse(string.match(/((\d\d\d\d\/)?\d?\d\/\d?\d)$/)[1])]
  end
end
