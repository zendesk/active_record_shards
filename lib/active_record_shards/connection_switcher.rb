# frozen_string_literal: true
require 'active_record_shards/shard_support'

module ActiveRecordShards
  module ConnectionSwitcher
    SHARD_NAMES_CONFIG_KEY = 'shard_names'.freeze

    def self.extended(base)
      base.singleton_class.send(:alias_method, :load_schema_without_default_shard!, :load_schema!)
      base.singleton_class.send(:alias_method, :load_schema!, :load_schema_with_default_shard!)

      base.singleton_class.send(:alias_method, :table_exists_without_default_shard?, :table_exists?)
      base.singleton_class.send(:alias_method, :table_exists?, :table_exists_with_default_shard?)
    end

    def on_shard(shard)
      old_selection = current_shard_selection
      switch_connection(ShardSelection.new(shard)) if supports_sharding?
      yield
    ensure
      switch_connection(old_selection)
    end

    def on_first_shard
      shard_name = shard_names.first
      on_shard(shard_name) { yield }
    end

    def shards
      ShardSupport.new(self == ActiveRecord::Base ? nil : where(nil))
    end

    def on_all_shards
      old_selection = current_shard_selection
      if supports_sharding?
        shard_names.map do |shard|
          switch_connection(ShardSelection.new(shard))
          yield(shard)
        end
      else
        [yield]
      end
    ensure
      switch_connection(old_selection)
    end

    def connection_config
      super.merge(current_shard_selection.connection_config.merge(sharded: is_sharded?))
    end

    def supports_sharding?
      shard_names.any?
    end

    def current_shard_selection
      Thread.current[:shard_selection] ||= NoShardSelection.new
    end

    def current_shard_selection=(shard_selection)
      Thread.current[:shard_selection] = shard_selection
    end

    def current_shard_id
      current_shard_selection.shard
    end

    def on_shard?
      current_shard_selection.on_shard?
    end

    def shard_names
      unless config = configurations[shard_env]
        raise "Did not find #{shard_env} in configurations, did you forget to add it to your database config? (configurations: #{configurations.inspect})"
      end
      unless config[SHARD_NAMES_CONFIG_KEY]
        raise "No shards configured for #{shard_env}"
      end
      unless config[SHARD_NAMES_CONFIG_KEY].all? { |shard_name| shard_name.is_a?(Integer) }
        raise "All shard names must be integers: #{config[SHARD_NAMES_CONFIG_KEY].inspect}."
      end
      config[SHARD_NAMES_CONFIG_KEY]
    end

    def table_exists_with_default_shard?
      with_default_shard { table_exists_without_default_shard? }
    end

    private

    def switch_connection(selection)
      if selection.is_a?(ShardSelection)
        unless config = configurations[shard_env]
          raise "Did not find #{shard_env} in configurations, did you forget to add it to your database config? (configurations: #{configurations.inspect})"
        end
        unless config['shard_names'].include?(selection.shard)
          raise "Did not find shard #{selection.shard} in configurations"
        end
        self.current_shard_selection = selection

        ensure_shard_connection
      else
        self.current_shard_selection = selection
      end
    end

    def shard_env
      ActiveRecordShards.rails_env
    end

    def with_default_shard
      if is_sharded? && current_shard_id.nil? && table_name != ActiveRecord::SchemaMigration.table_name
        on_first_shard { yield }
      else
        yield
      end
    end

    def load_schema_with_default_shard!
      with_default_shard { load_schema_without_default_shard! }
    end
  end
end

case "#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}"
when '5.0'
  require 'active_record_shards/connection_switcher_5_0'
when '5.1', '5.2'
  require 'active_record_shards/connection_switcher_5_1'
else
  raise "ActiveRecordShards is not compatible with #{ActiveRecord::VERSION::STRING}"
end
