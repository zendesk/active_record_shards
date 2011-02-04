require 'active_record_shards'
require 'active_record_shards/migration/shard_migration'

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

  desc "Create the database defined in config/database.yml for the current RAILS_ENV including shards and slaves"
  task :create => :load_config do
    env_name = defined?(Rails.env) ? Rails.env : RAILS_ENV || 'development'
    ActiveRecord::Base.configurations.each do |key, conf|
      if key.starts_with?(env_name) && !key.ends_with?("_slave")
        create_database(conf)
      end
    end
  end
end
