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
  has_many :requests, :through => :users

  after_create :create_or_update_users
  after_create :start_bot

  def self.create_or_update_team(auth_hash)
    # TO DO: should return some error
    return unless auth_hash.info.is_owner
    team = self.find_by(slack_id: auth_hash.info.team_id)
    if team
      team.update({ token: auth_hash.credentials.token })
    else
      Team.create({
        slack_id: auth_hash.info.team_id,
        token: auth_hash.credentials.token,
      })
    end
  end

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

# User model
class User < ApplicationRecord
  belongs_to :team
  has_many :requests

  def days_remaining
    allowance - days_taken
  end

  def all_days_requested
    requests.map{|request| request.days}.flatten
  end
end

# Request model
class Request < ApplicationRecord
  belongs_to :user

  enum status: [:pending, :approved, :rejected, :canceled]

  def start_date
    days.sort.first
  end

  def end_date
    days.sort.last
  end

  def duration
    days.length
  end

  def add_date(date)
    self.update({ days: days.push(date) }) unless days.include?(date)
  end

  def remove_date(date)
    self.update({ days: days - [date] })
  end
end

# Kyubot commands
class KyuBot < SlackRubyBot::Bot
  help do
    title 'KyuBot'
    desc 'This bot manages days off requests.'

    command 'request' do
      desc 'Request one or multiple days off'
    end

    command 'cancel' do
      desc 'Cancel one or multiple days off'
    end

    command 'list' do
      desc 'List yourself. If you are an owner you can list a particular user or list all'
    end

    command 'set' do
      desc 'Set leave allowance for a user'
    end
  end

  command 'request' do |client, data, match|
  end

  command 'cancel' do |client, data, match|
  end

  command 'list' do |client, data, match|
  end

  command 'set' do |client, data, match|
    command_user = get_user(data.user)
    return client.say(channel: data.channel, text: 'Sorry you are not an approver.') unless command_user.is_approver

    set_user = User.find_by(slack_id: get_first_mention(match['expression']))
    days = get_days(match['expression'])
    if set_user && days
      set_user.update({ allowance: days })
      client.say(channel: data.channel, text: "<@#{set_user.slack_id}> now has #{days} days allowance")
    else
      client.say(channel: data.channel, text: "Sorry I don't understand.")
    end
  end

  command 'say' do |client, data, match|
    client.say(channel: data.channel, text: match['expression'])
  end

  command 'ping' do |client, data, match|
    client.say(text: 'pong', channel: data.channel)
  end

  private
    def get_user(slack_id)
      User.find_by(slack_id: slack_id)
    end

    def get_team(slack_id)
      Team.find_by(slack_id: slack_id)
    end

    def get_first_mention(expression)
      return string[/<@(.*?)>/m, 1]
    end

    def get_days(expression)
      expression[/\d+/]
    end

end