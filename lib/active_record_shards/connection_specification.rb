# frozen_string_literal: true

class << ActiveRecord::Base
  remove_method :establish_connection if ActiveRecord::VERSION::MAJOR >= 5
  def establish_connection(spec = ENV["DATABASE_URL"])
    spec ||= ActiveRecord::ConnectionHandling::DEFAULT_ENV.call
    resolver = ActiveRecordShards::ConnectionSpecification::Resolver.new configurations
    spec = resolver.spec(spec)

    unless respond_to?(spec.adapter_method)
      raise AdapterNotFound, "database configuration specifies nonexistent #{spec.config[:adapter]} adapter"
    end

    remove_connection
    specification_cache[connection_pool_name] = spec
    connection_handler.establish_connection self, spec
  end
end
