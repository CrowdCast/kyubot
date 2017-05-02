class SlackController < ApplicationController
  skip_before_action :verify_authenticity_token

  def interactive
    # TO DO: Validate token
    # if params['token'] != 'NpAdZQwWDo0BErJjpRZg9AGE'
    #   render plain: 'Wrong token', status: 403
    #   return
    # end

    payload = JSON.parse(params['payload'])
    puts "payload #{payload}"
    puts "callback_id #{payload['callback_id']}"
    off_request = Request.find_by(id: payload['callback_id'])

    if payload['actions'][0]['value'] === 'yes'
      off_request.approved!
      off_request.user.team.service_client.post_message({
        "channel": "@#{off_request.user.slack_name}",
        "as_user": false,
        "text": "Your request has been approved."
      })
    elsif payload['actions'][0]['value'] === 'no'
      off_request.rejected!
      off_request.user.team.service_client.post_message({
        "channel": "@#{off_request.user.slack_name}",
        "as_user": false,
        "text": "Your request has been rejected."
      })
    end
    render json: { "text": "Cool. Thank you." }
  end
end