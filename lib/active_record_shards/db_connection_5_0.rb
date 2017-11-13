module ActiveRecordShards
  module BaseConfig
    private

    def ensure_db_connection
      # See if we've connected before. If not, call `#establish_connection`
      # so that ActiveRecord can resolve connection_specification_name to an
      # ARS connection.
      spec_name = connection_specification_name

      pool = connection_handler.retrieve_connection_pool(spec_name)
      if pool.nil?
        resolver = ActiveRecord::ConnectionAdapters::ConnectionSpecification::Resolver.new(configurations)
        spec = resolver.spec(spec_name.to_sym, spec_name)
        connection_handler.establish_connection(spec)
      end
    end
  end
end
