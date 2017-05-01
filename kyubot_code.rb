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

# Team class
class Team < ApplicationRecord
  has_many :users

  after_create :create_or_update_users
  after_create :start_bot

  def create_or_update_users
    users_hash = service_client.get_users
    users_hash.each { |user_hash|
      create_or_update_user(user_hash)
    }
  end

  def create_or_update_user(hash)
    user = User.find_by(team: self, slack_id: hash.id)
    if user
      user.update({
        name: hash.slack_name,
        is_approver: hash.is_admin || hash.is_owner || hash.is_primary_owner,
        is_deleted: hash.deleted,
      })
    else
      User.create({
        team: self,
        name: hash.slack_name,
        is_approver: hash.is_admin || hash.is_owner || hash.is_primary_owner,
        is_deleted: hash.deleted,
        slack_id: hash.id
      })
    end
  end

  def start_bot
    BotService.instance.start!(self)
  end

  def service_client
    @service ||= SlackWebService.new(self.token)
  end
end

# Slack web api service
class SlackWebService
  def initialize(token)
    @token = token
    @client ||= Slack::Client.new(token: @token)
  end

  def get_users
    @client.users_list.members
  end
end