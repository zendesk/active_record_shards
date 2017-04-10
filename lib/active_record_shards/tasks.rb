# frozen_string_literal: true
require 'active_record_shards'

known_tasks = Rake.application.tasks.map(&:name)
tasks_to_clear = %w[db:drop db:create db:abort_if_pending_migrations db:reset db:test:purge]
(known_tasks & tasks_to_clear).each do |name|
  Rake::Task[name].clear
end

namespace :db do
  desc 'Drops the database for the current RAILS_ENV including shards'
  task drop: :load_config do
    ActiveRecord::Base.configurations.each do |key, conf|
      next if !key.starts_with?(ActiveRecordShards.rails_env) || key.ends_with?("_slave")
      begin
        ActiveRecordShards::Tasks.root_connection(conf).drop_database(conf['database'])
      # rescue ActiveRecord::NoDatabaseError # TODO: exists in AR but never is raised here ...
      #   $stderr.puts "Database '#{conf['database']}' does not exist"
      rescue StandardError => error
        $stderr.puts error, *error.backtrace
        $stderr.puts "Couldn't drop #{conf['database']}"
      end
    end
  end

  task reset: :load_config do |t|
    Rake.application.lookup('db:drop', t.scope).invoke rescue nil # rubocop:disable Style/RescueModifier
    Rake.application.lookup('db:setup', t.scope).invoke
  end

  desc "Create the database defined in config/database.yml for the current RAILS_ENV including shards"
  task create: :load_config do
    ActiveRecord::Base.configurations.each do |key, conf|
      next if !key.starts_with?(ActiveRecordShards.rails_env) || key.ends_with?("_slave")
      if ActiveRecord::VERSION::MAJOR >= 4
        begin
          # MysqlAdapter takes charset instead of encoding in Rails 4
          # https://github.com/rails/rails/commit/78b30fed9336336694fb2cb5d2825f95800b541c
          symbolized_configuration = conf.symbolize_keys
          symbolized_configuration[:charset] = symbolized_configuration[:encoding]

          ActiveRecordShards::Tasks.root_connection(conf).create_database(conf['database'], symbolized_configuration)
        rescue ActiveRecord::StatementInvalid => ex
          if ex.message.include?('database exists')
            puts "#{conf['database']} already exists"
          else
            raise ex
          end
        end
      else
        create_database(conf)
      end
    end
    ActiveRecord::Base.establish_connection(ActiveRecordShards.rails_env.to_sym)
  end

  desc "Raises an error if there are pending migrations"
  task abort_if_pending_migrations: :environment do
    if defined? ActiveRecord
      pending_migrations =
        if Rails::VERSION::MAJOR >= 4
          ActiveRecord::Base.on_shard(nil) { ActiveRecord::Migrator.open(ActiveRecord::Migrator.migrations_paths).pending_migrations }
        else
          ActiveRecord::Base.on_shard(nil) { ActiveRecord::Migrator.new(:up, 'db/migrate').pending_migrations }
        end

      if pending_migrations.any?
        puts "You have #{pending_migrations.size} pending migrations:"
        pending_migrations.each do |pending_migration|
          puts '  %4d %s' % [pending_migration.version, pending_migration.name]
        end
        abort %(Run "rake db:migrate" to update your database then try again.)
      end
    end
  end

  namespace :test do
    desc 'Purges the test databases by dropping and creating'
    task purge: :load_config do |t|
      begin
        saved_env = Rails.env
        Rails.env = 'test'
        Rake.application.lookup('db:drop', t.scope).execute
        Rake.application.lookup('db:create', t.scope).execute
      ensure
        Rails.env = saved_env
      end
    end
  end
end

module ActiveRecordShards
  module Tasks
    if ActiveRecord::VERSION::MAJOR < 5
      def self.root_connection(conf)
        ActiveRecord::Base.send("#{conf['adapter']}_connection", conf.merge('database' => nil))
      end
    else
      def self.root_connection(conf)
        # this will trigger rails to load the adapter
        conf = conf.merge('database' => nil)
        resolver = ActiveRecord::ConnectionAdapters::ConnectionSpecification::Resolver.new(ActiveRecord::Base.configurations)
        resolver.spec(conf)
        ActiveRecord::Base.send("#{conf['adapter']}_connection", conf)
      end
    end
  end
end
