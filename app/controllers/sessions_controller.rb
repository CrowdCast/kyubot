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

      Team.create_or_update_team(response)

      render plain: "Auth succeeded."
    rescue Slack::Web::Api::Error => e
      render :text => "Auth failed. Reason: #{e.message}", :status => 403
    end
  end
end