require 'erb'
require 'yaml'

module DbHelper
  class << self
    def execute_sql(env_name, name, sql)
      config = DbHelper.database_configurations.fetch(env_name).fetch(name)
      client = Mysql2::Client.new(
        host: config['host'],
        port: config['port'],
        username: config['username'],
        password: config['password'],
        database: config['database']
      )
      client.query(sql)
    end

    def client
      @client ||= begin
        config = URI(ENV["MYSQL_URL"] || "mysql://root@127.0.0.1:3306")
        Mysql2::Client.new(
          username: config.user,
          password: config.password,
          host: config.host,
          port: config.port
        )
      end
    end

    def each_database(&_block)
      Dir.glob("test/schemas/*.sql").each do |schema_path|
        database_name = File.basename(schema_path, ".sql").to_s
        yield(database_name, schema_path)
      end
    end

    def mysql(commands)
      commands.split(/\s*;\s*/).reject(&:empty?).each do |command|
        client.query(command)
      end
    end

    def drop_databases
      each_database do |database_name, _schema_path|
        DbHelper.mysql("DROP DATABASE IF EXISTS #{database_name}")
      end
    end

    def create_databases
      each_database do |database_name, _schema_path|
        DbHelper.mysql("CREATE DATABASE IF NOT EXISTS #{database_name}")
      end
    end

    def load_database_schemas
      each_database do |database_name, schema_path|
        DbHelper.mysql("USE #{database_name}")
        DbHelper.mysql(File.read(schema_path))
      end
    end

    # Load the database configuration into ActiveRecord
    def load_database_configuration(path_or_io = 'test/database.yml')
      ActiveRecord::Base.configurations = database_configurations(path_or_io)
    end

    def database_configurations(path_or_io = 'test/database.yml')
      erb_config = path_or_io.is_a?(String) ? IO.read(path_or_io) : path_or_io.read
      yaml_config = ERB.new(erb_config, trim_mode: '-').result
      YAML.load(yaml_config) # rubocop:disable Security/YAMLLoad
    end
  end

  # Create all databases and then tear them down after test
  def with_fresh_databases
    before do
      DbHelper.drop_databases
      DbHelper.create_databases
      DbHelper.load_database_schemas

      clear_global_connection_handler_state
      DbHelper.load_database_configuration
    end

    after do
      DbHelper.drop_databases
    end
  end
end
