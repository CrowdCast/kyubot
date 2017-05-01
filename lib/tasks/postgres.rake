namespace :postgres do
  desc 'Force Remove All Postgres Sessions'
  task :destroy_sessions => :environment do
    version  = ActiveRecord::Base.connection.execute("select setting from pg_settings where name = 'server_version_num';").getvalue(0,0).to_i

    pid_name = version > 90200 ? 'pid' : 'procpid'

    ActiveRecord::Base.connection.execute <<-eos
      SELECT
        pg_terminate_backend(#{pid_name})
      FROM
        pg_stat_activity
      WHERE
        -- don't kill my own connection!
        #{pid_name} <> pg_backend_pid()
        -- don't kill the connections to other databases
      AND
        datname = '#{ ActiveRecord::Base.connection.current_database }'
      ;
    eos

  end
end
