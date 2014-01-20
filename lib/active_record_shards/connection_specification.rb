class ActiveRecord::Base
  def self.establish_connection(spec = ENV["DATABASE_URL"])
    resolver = ActiveRecordShards::ConnectionSpecification::Resolver.new spec, configurations
    spec = resolver.spec

    unless respond_to?(spec.adapter_method)
      raise AdapterNotFound, "database configuration specifies nonexistent #{spec.config[:adapter]} adapter"
    end

    remove_connection
    specification_cache[connection_pool_name] = spec

    if ActiveRecord::VERSION::STRING >= "4.0.0"
      connection_handler.establish_connection self, spec
    else
      connection_handler.establish_connection connection_pool_name, spec
    end
  end
end
