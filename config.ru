# This file is used by Rack-based servers to start the application.

require_relative 'config/environment'
require_relative 'app/services/bot_service'
require_relative 'app/bots/kyu_bot'
require_relative 'app/helpers/bot_helper'

Thread.abort_on_exception = true
# Thread.new do
#   KyuBot.run
# end

BotService.start!

run Rails.application
