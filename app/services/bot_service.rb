class BotService
  def self.start!
    puts 'BotService starting'
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
    puts "Starting bot for team #{team}."
    bot = SlackRubyBot::Server.new(token: team.bot_access_token)
    bot.start_async
  rescue => e
    puts e.inspect
  end
end