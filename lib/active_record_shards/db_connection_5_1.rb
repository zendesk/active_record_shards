module ActiveRecordShards
  module BaseConfig
    private

    def ensure_shard_connection
      # See if we've connected before. If not, call `#establish_connection`
      # so that ActiveRecord can resolve connection_specification_name to an
      # ARS connection.
      spec_name = connection_specification_name

      pool = connection_handler.retrieve_connection_pool(spec_name)
      connection_handler.establish_connection(spec_name.to_sym) if pool.nil?
    end
  end
end
