class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  def home
    render text: 'Kyubot'
  end
end
