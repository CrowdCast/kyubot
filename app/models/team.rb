class Team < ApplicationRecord
  has_many :users
  has_many :requests, :through => :users

  after_create :start_bot
  after_save :create_or_update_users

  def self.create_or_update_team(auth_hash)
    team = self.find_by(slack_id: auth_hash['team_id'])
    if team
      team.update({
        access_token: auth_hash['access_token'],
        bot_access_token: auth_hash['bot']['bot_access_token']
      })
    else
      Team.create({
        slack_id: auth_hash['team_id'],
        access_token: auth_hash['access_token'],
        bot_access_token: auth_hash['bot']['bot_access_token']
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
    user = User.find_by(team: self, slack_id: hash['id'])
    if user
      user.update({
        slack_name: hash['name'],
        is_approver: hash['is_admin'] || hash['is_owner'] || hash['is_primary_owner'],
        # is_deleted: hash['deleted'],
      })
    elsif !hash['deleted']
      User.create({
        team: self,
        slack_name: hash['name'],
        is_approver: hash['is_admin'] || hash['is_owner'] || hash['is_primary_owner'],
        # is_deleted: hash['deleted'],
        slack_id: hash['id'],
      })
    end
  end

  def start_bot
    # TO DO: add BotService
    # BotService.instance.start!(self)
  end

  def service_client
    @service ||= SlackWebService.new(self.access_token)
  end
end