# Potential code we can use
# Inspired by https://github.com/slack-ruby/slack-ruby-bot-server

# Initialize bot service
# config/initializers/bot_service_initializer.rb
# or in application.rb
BotService.start!

# Bot service
# app/services/bot_service.rb
class BotService
  def self.start!
    puts '----------BotService starting----------'
    Thread.new do
      Thread.current.abort_on_exception = true
      instance.start_from_database!
    end
  end

  def self.instance
    @instance ||= new
  end

  def start_from_database!
    Team.all.each do |team|
      start!(team)
    end
  end

  def start!(team)
    puts "Starting team #{team}."
    bot = Bot.new(team: team)
    bot.start_async
  rescue => e
    puts e.inspect
  end
end

# Bot instances
# app/bot/bot.rb
class Bot < SlackRubyBot::Server
  attr_accessor :team

  def initialize(attrs = {})
    attrs = attrs.dup
    @team = attrs.delete(:team)
    raise 'Missing team' unless @team
    attrs[:token] = @team.token
    super(attrs)
    client.owner = @team
  end
end