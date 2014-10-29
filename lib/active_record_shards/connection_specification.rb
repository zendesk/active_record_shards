class ActiveRecord::Base
  def self.establish_connection(spec = ENV["DATABASE_URL"])
    if ActiveRecord::VERSION::MAJOR == 4 && ActiveRecord::VERSION::MINOR == 1
      spec ||= DEFAULT_ENV.call
      spec = spec.to_sym if spec.is_a?(String)
      resolver = ActiveRecordShards::ConnectionSpecification::Resolver.new configurations
      spec = resolver.spec(spec)
    else
      resolver = ActiveRecordShards::ConnectionSpecification::Resolver.new spec, configurations
      spec = resolver.spec
    end

    unless respond_to?(spec.adapter_method)
      raise AdapterNotFound, "database configuration specifies nonexistent #{spec.config[:adapter]} adapter"
    end

    remove_connection
    specification_cache[connection_pool_name] = spec

    if ActiveRecord::VERSION::MAJOR >= 4
      connection_handler.establish_connection self, spec
    else
      connection_handler.establish_connection connection_pool_name, spec
    end
  end
end
