# frozen_string_literal: true

require_relative 'helper'

# ActiveRecordShards overrides some of the ActiveRecord tasks, so
# ActiveRecord needs to be loaded first.
Rake::Application.new.rake_require("active_record/railties/databases")
require 'active_record_shards/tasks'
task :environment do
  # Only required as a dependency
end

describe "Database rake tasks" do
  include RakeSpecHelpers

  def capture_stderr
    $stderr = StringIO.new
    yield
    $stderr.string
  ensure
    $stderr = STDERR
  end

  let(:config) { Phenix.load_database_config('test/database_tasks.yml') }
  let(:primary_name) { config['test']['database'] }
  let(:replica_name) { config['test']['replica']['database'] }
  let(:shard_names) { config['test']['shards'].values.map { |v| v['database'] } }
  let(:database_names) { shard_names + [primary_name, replica_name] }

  before do
    clear_global_connection_handler_state

    ActiveRecord::Tasks::DatabaseTasks.database_configuration = config
    ActiveRecord::Tasks::DatabaseTasks.env = RAILS_ENV
    ActiveRecord::Tasks::DatabaseTasks.migrations_paths = '/app/migrations'
  end

  after do
    Phenix.configure
    Phenix.burn!
  end

  describe "db:create" do
    it "creates the database and all shards" do
      rake('db:create')
      databases = show_databases(config)

      assert_includes databases, primary_name
      refute_includes databases, replica_name
      shard_names.each do |name|
        assert_includes databases, name
      end
    end
  end

  describe "db:drop" do
    it "drops the database and all shards" do
      rake('db:create')
      rake('db:drop')
      databases = show_databases(config)

      refute_includes databases, primary_name
      shard_names.each do |name|
        refute_includes databases, name
      end
    end

    it "does not fail when db is missing" do
      rake('db:create')
      rake('db:drop')
      refute_includes(show_databases(config), primary_name)
    end

    it "fails loudly when unknown error occurs" do
      ActiveRecordShards::Tasks.stubs(:root_connection).raises(ArgumentError)
      out = capture_stderr { rake('db:drop') }
      assert_includes(out, "Couldn't drop ")
      assert_includes(out, "test/helper.rb")
    end
  end

  describe "abort_if_pending_migrations" do
    before do
      rake('db:create')
    end

    it "passes when there is no pending migrations" do
      ActiveRecord::Migrator.any_instance.stubs(:pending_migrations).returns([])
      out = capture_stderr { rake('db:abort_if_pending_migrations') }
      assert_empty out
    end

    it "fails when migrations are pending" do
      ActiveRecord::Migrator.any_instance.stubs(:pending_migrations).returns([stub(version: 1, name: 'Fake')])
      out = capture_stderr do
        begin
          rake('db:abort_if_pending_migrations')
        rescue SystemExit
          ""
        end
      end
      assert_match(/You have \d+ pending migrations:/, out)
    end
  end
end
