# frozen_string_literal: true

require 'active_support/core_ext'

module ActiveRecordShards
  module ConfigurationParser
    module_function

    def explode(conf)
      conf = conf.to_h.deep_dup

      conf.to_a.each do |env_name, env_config|
        next unless shards = env_config.delete('shards')

        unless shards.keys.all? { |shard_name| shard_name.is_a?(Integer) }
          raise "All shard names must be integers: #{shards.keys.inspect}."
        end

        env_config['shard_names'] = shards.keys
        shards.each do |shard_name, shard_conf|
          expand_child!(env_config, shard_conf)
          conf["#{env_name}_shard_#{shard_name}"] = shard_conf
        end
      end

      conf.to_a.each do |env_name, env_config|
        if replica_conf = env_config.delete('replica')
          expand_child!(env_config, replica_conf)
          conf["#{env_name}_replica"] = replica_conf
        end
      end

      conf
    end

    def expand_child!(parent, child)
      parent.each do |key, value|
        unless ['replica', 'shards'].include?(key) || value.is_a?(Hash)
          child[key] ||= value
        end
      end
    end

    def configurations_with_shard_explosion=(conf)
      self.configurations_without_shard_explosion = explode(conf)
    end

    def self.extended(base)
      base.singleton_class.send(:alias_method, :configurations_without_shard_explosion=, :configurations=)
      base.singleton_class.send(:alias_method, :configurations=, :configurations_with_shard_explosion=)
      base.singleton_class.send(:public, :configurations=)

      base.configurations = base.configurations if base.configurations.present?
    end
  end
end
