# frozen_string_literal: true

require 'active_record_shards'

%w[db:drop db:create db:abort_if_pending_migrations db:reset db:test:purge].each do |name|
  Rake::Task[name].clear
end

namespace :db do
  desc 'Drops the database for the current RAILS_ENV including shards'
  task drop: :load_config do
    ActiveRecord::Base.configurations.to_h.each do |key, conf|
      next if !key.start_with?(ActiveRecordShards.rails_env) || key.end_with?("_replica")

      begin
        ActiveRecordShards::Tasks.root_connection(conf).drop_database(conf['database'])
      # rescue ActiveRecord::NoDatabaseError # TODO: exists in AR but never is raised here ...
      #   $stderr.puts "Database '#{conf['database']}' does not exist"
      rescue StandardError => e
        warn e, *e.backtrace
        warn "Couldn't drop #{conf['database']}"
      end
    end
  end

  task reset: :load_config do |t|
    Rake.application.lookup('db:drop', t.scope).invoke rescue nil # rubocop:disable Style/RescueModifier
    Rake.application.lookup('db:setup', t.scope).invoke
  end

  desc "Create the database defined in config/database.yml for the current RAILS_ENV including shards"
  task create: :load_config do
    ActiveRecord::Base.configurations.to_h.each do |key, conf|
      next if !key.start_with?(ActiveRecordShards.rails_env) || key.end_with?("_replica")

      begin
        # MysqlAdapter takes charset instead of encoding in Rails 4.2 or greater
        # https://github.com/rails/rails/blob/4-2-stable/activerecord/lib/active_record/tasks/mysql_database_tasks.rb#L85-L96
        symbolized_configuration = conf.symbolize_keys
        symbolized_configuration[:charset] = symbolized_configuration[:encoding]

        ActiveRecordShards::Tasks.root_connection(conf).create_database(conf['database'], symbolized_configuration)
      rescue ActiveRecord::StatementInvalid => e
        if e.message.include?('database exists')
          puts "#{conf['database']} already exists"
        else
          raise e
        end
      end
    end
    ActiveRecord::Base.establish_connection(ActiveRecordShards.rails_env.to_sym)
  end

  desc "Raises an error if there are pending migrations"
  task abort_if_pending_migrations: :environment do
    if defined? ActiveRecord
      pending_migrations =
        if ActiveRecord::VERSION::MAJOR >= 6
          migrations = ActiveRecord::MigrationContext.new(ActiveRecord::Migrator.migrations_paths, ActiveRecord::SchemaMigration).migrations
          ActiveRecord::Migrator.new(:up, migrations, ActiveRecord::SchemaMigration).pending_migrations
        elsif ActiveRecord::VERSION::STRING >= "5.2.0"
          migrations = ActiveRecord::MigrationContext.new(ActiveRecord::Migrator.migrations_paths).migrations
          ActiveRecord::Migrator.new(:up, migrations).pending_migrations
        else
          ActiveRecord::Base.on_shard(nil) { ActiveRecord::Migrator.open(ActiveRecord::Migrator.migrations_paths).pending_migrations }
        end

      if pending_migrations.any?
        warn "You have #{pending_migrations.size} pending migrations:"
        pending_migrations.each do |pending_migration|
          warn '  %4d %s' % [pending_migration.version, pending_migration.name]
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
    class << self
      def root_connection(conf)
        conf = conf.merge('database' => nil)
        spec = spec_for(conf)

        ActiveRecord::Base.send("#{conf['adapter']}_connection", spec.config)
      end

      private

      def spec_for(conf)
        resolver = ActiveRecord::ConnectionAdapters::ConnectionSpecification::Resolver.new(ActiveRecord::Base.configurations)
        resolver.spec(conf)
      end
    end
  end
end
