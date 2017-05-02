class SlackWebService
  def initialize(token)
    @token = token
    @client ||= Slack::Web::Client.new(token: @token)
  end

  def get_users
    @client.users_list.members
  end

  def post_message(json_param)
    @client.chat_postMessage(json_param)
  end
end