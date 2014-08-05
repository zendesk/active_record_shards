module ActiveRecordShards
  module SchemaDumperExtension

    def dump(stream)
      stream = super(stream)
      original_connection = @connection

      if ActiveRecord::Base.supports_sharding?
        ActiveRecord::Base.on_first_shard do
          @connection = ActiveRecord::Base.connection
          shard_header(stream)
          extensions(stream)
          tables(stream)
          shard_trailer(stream)
        end
      end

      stream
    ensure
      @connection = original_connection
    end


    def shard_header(stream)
      define_params = @version ? "version: #{@version}" : ""

      stream.puts <<HEADER


# This section generated by active_record_shards

ActiveRecord::Base.on_all_shards do
ActiveRecord::Schema.define(#{define_params}) do

HEADER
      end

    def shard_trailer(stream)
      stream.puts "end\nend"
    end

  end
end