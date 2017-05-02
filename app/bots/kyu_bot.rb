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
end