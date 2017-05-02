class SlackWebService
  def initialize(token)
    @token = token
    @client ||= Slack::Web::Client.new(token: @token)
  end

  def get_users
    @client.users_list.members
  end
end