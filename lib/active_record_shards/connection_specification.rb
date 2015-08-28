class ActiveRecord::Base
  def self.establish_connection(spec = ENV["DATABASE_URL"])
    if ActiveRecord::VERSION::MAJOR == 4 && ActiveRecord::VERSION::MINOR >= 1
      spec ||= ActiveRecord::ConnectionHandling::DEFAULT_ENV.call
      spec = spec.to_sym if spec.is_a?(String)
      resolver = ActiveRecord::ConnectionAdapters::ConnectionSpecification::Resolver.new configurations
      spec = resolver.spec(spec)
    else
      resolver = ActiveRecord::ConnectionAdapters::ConnectionSpecification::Resolver.new spec, configurations
      spec = resolver.spec
    end

    unless respond_to?(spec.adapter_method)
      raise AdapterNotFound, "database configuration specifies nonexistent #{spec.config[:adapter]} adapter"
    end

    remove_connection
    specification_cache[connection_pool_name] = spec

    connection_handler.establish_connection self, spec
  end
end
