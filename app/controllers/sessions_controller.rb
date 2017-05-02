class SessionsController < ApplicationController
  def new
  end

  def auth
    client = Slack::Web::Client.new
    begin
      response = client.oauth_access(
        {
          client_id: ENV['SLACK_APP_ID'],
          client_secret: ENV['SLACK_APP_SECRET'],
          redirect_uri: ENV['SLACK_APP_REDIRECT_URL'],
          code: params[:code]
        }
      )

      team = Team.find_or_initialize_by(slack_id: response['team_id'])
      team.slack_token = response['bot']['bot_access_token']
      team.save

      render plain: "Auth succeeded."
    rescue Slack::Web::Api::Error => e
      render :text => "Auth failed. Reason: #{e.message}", :status => 403
    end
  end
end