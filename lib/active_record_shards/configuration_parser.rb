module ActiveRecordShards
  module ConfigurationParser
    module_function

    def explode(conf)
      conf.keys.each do |env_name|
        env_config = conf[env_name]
        if shards = env_config.delete('shards')
          env_config['shard_names'] = shards.keys
          shards.each do |shard_name, shard_conf|
            expand_child!(env_config, shard_conf)
            conf["#{env_name}_shard_#{shard_name}"] = shard_conf
          end
        end
      end

      conf.keys.each do |env_name|
        env_config = conf[env_name]
        if slave_conf = env_config.delete('slave')
          expand_child!(env_config, slave_conf)
          conf["#{env_name}_slave"] = slave_conf
        end
      end
      conf
    end

    def expand_child!(parent, child)
      parent.each do |key, value|
        unless ['slave', 'shards'].include?(key) || value.is_a?(Hash)
          child[key] ||= value
        end
      end
    end

    def configurations_with_shard_explosion=(conf)
      self.configurations_without_shard_explosion = explode(conf)
    end

    def ConfigurationParser.extended(klass)
      klass.singleton_class.alias_method_chain :configurations=, :shard_explosion

      if !klass.configurations.nil? && !klass.configurations.empty?
        klass.configurations = klass.configurations
      end
    end
  end
end
