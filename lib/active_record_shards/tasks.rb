require 'active_record_shards'

Rake::TaskManager.class_eval do
  def remove_task(task_name)
    @tasks.delete(task_name.to_s)
  end
end

def remove_task(task_name)
  Rake.application.remove_task(task_name)
end

remove_task 'db:drop'
remove_task 'db:create'
remove_task 'db:abort_if_pending_migrations'
remove_task 'db:reset'

namespace :db do
  desc 'Drops the database for the current RAILS_ENV including shards and slaves'
  task :drop => :load_config do
    env_name = defined?(Rails.env) ? Rails.env : RAILS_ENV || 'development'
    ActiveRecord::Base.configurations.each do |key, conf|
      if key.starts_with?(env_name) && !key.ends_with?("_slave")
        drop_database(conf)
      end
    end
  end

  task :reset => :load_config do
    Rake::Task["db:drop"].invoke rescue nil
    Rake::Task["db:setup"].invoke
  end

  desc "Create the database defined in config/database.yml for the current RAILS_ENV including shards and slaves"
  task :create => :load_config do
    env_name = defined?(Rails.env) ? Rails.env : RAILS_ENV || 'development'
    ActiveRecord::Base.configurations.each do |key, conf|
      if key.starts_with?(env_name) && !key.ends_with?("_slave")
        create_database(conf)
      end
    end
  end

  desc "Raises an error if there are pending migrations"
  task :abort_if_pending_migrations => :environment do
    if defined? ActiveRecord
      pending_migrations = ActiveRecord::Base.on_shard(nil) { ActiveRecord::Migrator.new(:up, 'db/migrate').pending_migrations }

      if pending_migrations.any?
        puts "You have #{pending_migrations.size} pending migrations:"
        pending_migrations.each do |pending_migration|
          puts '  %4d %s' % [pending_migration.version, pending_migration.name]
        end
        abort %{Run "rake db:migrate" to update your database then try again.}
      end
    end
  end
end
