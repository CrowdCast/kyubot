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

  def send_to_approver
    # TO DO: Call Slack service to message approvers
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
    command_user = get_user(data.user)
    request_dates = get_dates(match['expression'])

    unless (command_user.all_days_requested & request_dates).empty?
      client.say(channel: data.channel, text: 'Sorry you have already requested 1 or more of those dates')
    end

    request = Request.create({
      user: command_user,
      days: request_dates,
      description: get_description(match['expression']),
    })
    request.send_to_approver

    client.say(channel: data.channel, text: 'Thanks! Your request has been made')
  end

  command 'cancel' do |client, data, match|
    command_user = get_user(data.user)
    cancel_dates = get_dates(match['expression'])
    canceled_dates = []

    client.say(channel: data.channel, text: "Sorry I don't understand.") unless cancel_dates

    # TO DO: much more efficient way of handling this because this current code makes me sad
    cancel_dates.each{|date|
      command_user.requests.each{|request|
        if request.days.include?(date)
          request.remove_date(date)
          canceled_dates.push(date)
        end
      }
    }

    if canceled_dates.empty?
      client.say(channel: data.channel, text: "No dates need to be canceled.")
    else
      client.say(channel: data.channel, text: "Canceled your requests.")
    end
  end

  # TO DO: make this more DRY
  command 'list' do |client, data, match|
    command_user = get_user(data.user)

    if match['expression'].nil?
      list_string = build_request_list_for_user(command_user)
      return client.say(channel: data.channel, text: list_string)
    end

    return client.say(channel: data.channel, text: 'Sorry you are not an approver.') unless command_user.is_approver

    set_user = User.find_by(slack_id: get_first_mention(match['expression']))

    if set_user
      list_string = build_request_list_for_user(set_user)
      return client.say(channel: data.channel, text: list_string)
    elsif match['expression'] === 'all'
      list_string = build_request_list_for_team(command_user.team)
      return client.say(channel: data.channel, text: list_string)
    end

    return client.say(channel: data.channel, text: "Sorry I don't understand.")

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
      get_expression_without_mentions(expression)[/\d+/]
    end

    def get_dates(expression)
      string = get_expression_without_mentions(expression)
      dateArray = []

      # set strings to be lowercase
      string.downcase

      # from <YYYY/MM/DD>
      if string.match(/^from\s+((\d\d\d\d\/)?\d?\d\/\d?\d)/)
        fromDate = Date.parse(string.match(/^from\s+((\d\d\d\d\/)?\d?\d\/\d?\d)/)[1])
      end

      # today
      if string.match(/today/)
        fromDate = Date.today
      end

      # to <YYYY/MM/DD>
      if string.match(/to\s+((\d\d\d\d\/)?\d?\d\/\d?\d)/)
        toDate = Date.parse(string.match(/to\s+((\d\d\d\d\/)?\d?\d\/\d?\d)/)[1])

        (toDate - fromDate).to_i.times do |x| dateArray << fromDate+x end
        dateArray << toDate
        return dateArray
      end

      # days from
      if string.match(/(\d)+\s+days/)
        # since index is zero indexed
        index = string.match(/(\d)+\s+days/)[1].to_i
        index.times do |x| dateArray << fromDate+x end
        return dateArray
      end

      # Single date entry
      # Parse date, date format is [YYYY/]?M?M/D?D
      [Date.parse(string.match(/((\d\d\d\d\/)?\d?\d\/\d?\d)$/)[1])]
    end

    def get_description(expression)
      # Regex to get description text from a days off requesst
      nonDescription = expression.match(/(.*\sfor\s)/)[1]
      expression.gsub(nonDescription, '')
    end

    def get_expression_without_mentions(expression)
      # Regex to remove out mentions <@FOO> from expression
      user = expression.match(/(<@.*>)/)[1]
      expression.gsub(user,'')
    end

    def build_request_list_for_user(user)
      if user.requests.any?
        # TO DO: Build a message with all the user requests
      else
        return "<@#{user.slack_id}> has no requests"
      end
    end

    def build_request_list_for_team(team)
      list_string = ""
      team.users.each {|user|
        list_string << "\n#{build_request_list_for_user(user)}"
      }
      return list_string
    end

end
