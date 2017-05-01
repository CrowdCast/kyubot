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

  command 'list' do |client, data, match|
    if match['expression']
      user = User.where(slack_name: match['expression'])
      client.say(text: user.allowance)
      client.say(text: 'theres nothing to list', channel: data.channel)
    else
      user = User.all()
      client.say(text: 'listen to my hearttt', channel: data.channel)
    end
  end

end
