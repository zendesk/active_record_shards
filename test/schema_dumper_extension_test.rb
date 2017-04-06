# frozen_string_literal: true
require_relative 'helper'

describe ActiveRecordShards::SchemaDumperExtension do
  describe "schema dump" do
    let(:schema_file) { Tempfile.new('active_record_shards_schema.rb') }

    with_phenix

    before do
      ActiveRecord::Base.establish_connection(RAILS_ENV.to_sym)

      # create shard-specific columns
      ActiveRecord::Migrator.migrations_paths = [File.join(File.dirname(__FILE__), "/migrations")]
      ActiveRecord::Migrator.migrate(ActiveRecord::Migrator.migrations_paths)
    end

    after { schema_file.unlink }

    it "includes the sharded tables" do
      ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, schema_file)
      schema_file.close

      Phenix.rise! # Recreate the database without loading the schema
      load(schema_file)

      ActiveRecord::Base.on_all_shards do
        assert ActiveRecord::Base.connection.data_source_exists?(:schema_migrations), "Schema Migrations doesn't exist"
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
