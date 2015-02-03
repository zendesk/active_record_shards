require 'active_record_shards'

%w[db:drop db:create db:abort_if_pending_migrations db:reset db:test:purge].each do |name|
  Rake::Task[name].clear
end

def env_name
  defined?(Rails.env) ? Rails.env : RAILS_ENV || 'development'
end

namespace :db do
  desc 'Drops the database for the current RAILS_ENV including shards'
  task :drop => :load_config do
    ActiveRecord::Base.configurations.each do |key, conf|
      if key.starts_with?(env_name) && !key.ends_with?("_slave")
        begin
          if ActiveRecord::VERSION::MAJOR >= 4
            connection = ActiveRecord::Base.send("#{conf['adapter']}_connection", conf.merge('database' => nil))
            connection.drop_database(conf['database'])
          else
            drop_database(conf)
          end
        rescue Exception => e
          puts "Couldn't drop #{conf['database']} : #{e.inspect}"
        end
      end
    end
  end

  task :reset => :load_config do
    Rake::Task["db:drop"].invoke rescue nil
    Rake::Task["db:setup"].invoke
  end

  desc "Create the database defined in config/database.yml for the current RAILS_ENV including shards"
  task :create => :load_config do
    ActiveRecord::Base.configurations.each do |key, conf|
      if key.starts_with?(env_name) && !key.ends_with?("_slave")
        if ActiveRecord::VERSION::MAJOR >= 4
          begin
            connection = ActiveRecord::Base.send("#{conf['adapter']}_connection", conf.merge('database' => nil))
            connection.create_database(conf['database'])
          rescue ActiveRecord::StatementInvalid => ex
            if ex.message.match('database exists')
              $stderr.puts "#{conf['database']} already exists"
            else
              raise ex
            end
          end
        else
          create_database(conf)
        end
      end
    end
    ActiveRecord::Base.establish_connection(env_name)
  end

  desc "Raises an error if there are pending migrations"
  task :abort_if_pending_migrations => :environment do
    if defined? ActiveRecord
      if Rails::VERSION::MAJOR >= 4
        pending_migrations = ActiveRecord::Base.on_shard(nil) { ActiveRecord::Migrator.open(ActiveRecord::Migrator.migrations_paths).pending_migrations }
      else
        pending_migrations = ActiveRecord::Base.on_shard(nil) { ActiveRecord::Migrator.new(:up, 'db/migrate').pending_migrations }
      end

      if pending_migrations.any?
        puts "You have #{pending_migrations.size} pending migrations:"
        pending_migrations.each do |pending_migration|
          puts '  %4d %s' % [pending_migration.version, pending_migration.name]
        end
        abort %{Run "rake db:migrate" to update your database then try again.}
      end
    end
  end

  namespace :test do
    desc 'Purges the test databases by dropping and creating'
    task :purge do
      begin
        saved_env = Rails.env
        Rails.env = 'test'
        Rake::Task['db:drop'].invoke
        Rake::Task['db:create'].invoke
      ensure
        Rails.env = saved_env
      end
    end
  end
end
