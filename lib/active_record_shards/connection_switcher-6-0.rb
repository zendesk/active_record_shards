module ActiveRecordShards
  module ConnectionSwitcher
    def connection_specification_name
      name = current_shard_selection.resolve_connection_name(sharded: is_sharded?, configurations: configurations)

      @_ars_connection_specification_names ||= {}
      unless @_ars_connection_specification_names.include?(name)
        unless configurations.configs_for(env_name: ENV['RAILS_ENV'], name: name, include_replicas: true) || name == "default"
          raise ActiveRecord::AdapterNotSpecified, "No database defined by #{name} in your database config. (configurations: #{configurations.inspect})"
        end

        @_ars_connection_specification_names[name] = true
      end

      name
    end

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
