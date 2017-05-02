module BotHelper
  extend self

  def get_user(slack_id)
    User.find_by(slack_id: slack_id)
  end

  def get_team(slack_id)
    Team.find_by(slack_id: slack_id)
  end

  def get_first_mention(expression)
    return expression[/<@(.*?)>/m, 1]
  end

  def get_days(expression)
    get_expression_without_mentions(expression)[/\d+/]
  end

  def get_dates(expression)
    # set strings to be lowercase
    string = expression.downcase

    dates = []

    # from <YYYY/MM/DD>
    if string.match(/from\s+((\d\d\d\d\/)?\d?\d\/\d?\d)/)
      date_from = Date.parse(string.match(/from\s+((\d\d\d\d\/)?\d?\d\/\d?\d)/)[1])
    end

    # today
    if string.match(/today/)
      date_from = Date.today
    end

    # to <YYYY/MM/DD>
    if string.match(/to\s+((\d\d\d\d\/)?\d?\d\/\d?\d)/)
      date_to = Date.parse(string.match(/to\s+((\d\d\d\d\/)?\d?\d\/\d?\d)/)[1])

      (date_to - date_from).to_i.times do |x| dates << date_from+x end
      dates << date_to
      return dates
    end

    # days from
    if string.match(/(\d)+\s+days/)
      # since index is zero indexed
      index = string.match(/(\d)+\s+days/)[1].to_i
      index.times do |x| dates << date_from+x end
      return dates
    end

    # Single date entry
    # Parse date, date format is [YYYY/]?M?M/D?D
    return [Date.parse(string.match(/((\d\d\d\d\/)?\d?\d\/\d?\d)$/)[1])]
  end

  def get_description(expression)
    # Regex to get description text from a days off requesst
    non_description = expression.match(/(.*\sfor\s)/)[1]
    expression.gsub(non_description, '')
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