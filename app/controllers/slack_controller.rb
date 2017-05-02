class SlackController < ApplicationController
  def interactive
    puts params
    render json: { "text": "Cool. Thank you." }
  end
end