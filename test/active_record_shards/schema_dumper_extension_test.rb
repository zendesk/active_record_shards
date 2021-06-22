# frozen_string_literal: true

require_relative '../helper'

describe ActiveRecordShards::SchemaDumperExtension do
  describe "schema dump" do
    let(:schema_file) { Tempfile.new('active_record_shards_schema.rb') }

    with_fresh_databases

    before do
      ActiveRecord::Base.establish_connection(RAILS_ENV.to_sym)

      # create shard-specific columns
      ActiveRecord::Migrator.migrations_paths = [File.join(__dir__, "../support/migrations")]
      migrator.migrate
    end

    after { schema_file.unlink }

    it "includes the sharded tables" do
      ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, schema_file)
      schema_file.close

      # Recreate the database without loading the schema
      DbHelper.drop_databases
      DbHelper.create_databases

      load(schema_file)

      ActiveRecord::Base.on_all_shards do
        assert table_exists?(:schema_migrations), "Schema Migrations doesn't exist"
        assert ActiveRecord::Base.connection.select_value("select version from schema_migrations where version = '20110824010216'")
        assert ActiveRecord::Base.connection.select_value("select version from schema_migrations where version = '20110829215912'")
      end

      ActiveRecord::Base.on_all_shards do
        assert table_has_column?("tickets", "sharded_column")
      end

      ActiveRecord::Base.on_shard(nil) do
        assert table_has_column?("accounts", "non_sharded_column")
      end
    end
  end
end
