require 'active_support/core_ext'

module ActiveRecordShards
  module ConfigurationParser
    module_function

    def explode(conf)
      conf = conf.deep_dup

      conf.to_a.each do |env_name, env_config|
        if shards = env_config.delete('shards')
          env_config['shard_names'] = shards.keys
          shards.each do |shard_name, shard_conf|
            expand_child!(env_config, shard_conf)
            conf["#{env_name}_shard_#{shard_name}"] = shard_conf
          end
        end
      end

      conf.to_a.each do |env_name, env_config|
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

    module PrependMethods
      def configurations=(conf)
        super(explode(conf))
      end
    end

    def ConfigurationParser.extended(klass)
      klass.singleton_class.send(:prepend, PrependMethods)
      klass.configurations = klass.configurations if klass.configurations.present?
    end
  end
end
