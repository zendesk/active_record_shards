require File.expand_path('../helper', __FILE__)


describe ActiveRecordShards::SchemaDumperExtension do
  describe "schema dump" do

    let(:schema_file) { Tempfile.new('active_record_shards_schema.rb') }
    before do
      init_schema

      # create shard-specific columns
      ActiveRecord::Migrator.migrations_paths = [File.join(File.dirname(__FILE__), "/migrations")]
      ActiveRecord::Migrator.migrate(ActiveRecord::Migrator.migrations_path)
    end

    after do
      schema_file.unlink
      init_schema
    end

    it "includes the sharded tables" do
      ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, schema_file)
      schema_file.close

      recreate_databases
      load(schema_file)

      ActiveRecord::Base.on_all_shards do
        assert ActiveRecord::Base.connection.table_exists?(:schema_migrations), "Schema Migrations doesn't exist"
        assert ActiveRecord::Base.connection.table_exists?(:accounts)
        assert ActiveRecord::Base.connection.select_value("select version from schema_migrations where version = '20110824010216'")
        assert ActiveRecord::Base.connection.select_value("select version from schema_migrations where version = '20110829215912'")
      end

      ActiveRecord::Base.on_all_shards do
        assert table_has_column?("emails", "sharded_column")
        assert !table_has_column?("accounts", "non_sharded_column")
      end

      ActiveRecord::Base.on_shard(nil) do
        assert !table_has_column?("emails", "sharded_column")
        assert table_has_column?("accounts", "non_sharded_column")
      end
    end
  end
end
