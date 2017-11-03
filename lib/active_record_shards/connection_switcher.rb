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
      old_options = current_shard_selection.options
      switch_connection(shard: shard) if supports_sharding?
      yield
    ensure
      switch_connection(old_options)
    end

    def on_first_shard
      shard_name = shard_names.first
      on_shard(shard_name) { yield }
    end

    def shards
      ShardSupport.new(self == ActiveRecord::Base ? nil : where(nil))
    end

    def on_all_shards
      old_options = current_shard_selection.options
      if supports_sharding?
        shard_names.map do |shard|
          switch_connection(shard: shard)
          yield(shard)
        end
      else
        [yield]
      end
    ensure
      switch_connection(old_options)
    end

    def on_slave_if(condition, &block)
      condition ? on_slave(&block) : yield
    end

    def on_slave_unless(condition, &block)
      on_slave_if(!condition, &block)
    end

    def on_master_if(condition, &block)
      condition ? on_master(&block) : yield
    end

    def on_master_unless(condition, &block)
      on_master_if(!condition, &block)
    end

    def on_master_or_slave(which, &block)
      if block_given?
        on_cx_switch_block(which, &block)
      else
        MasterSlaveProxy.new(self, which)
      end
    end

    # Executes queries using the slave database. Fails over to master if no slave is found.
    # if you want to execute a block of code on the slave you can go:
    #   Account.on_slave do
    #     Account.first
    #   end
    # the first account will be found on the slave DB
    #
    # For one-liners you can simply do
    #   Account.on_slave.first
    def on_slave(&block)
      on_master_or_slave(:slave, &block)
    end

    def on_master(&block)
      on_master_or_slave(:master, &block)
    end

    def force_cx_switch_slave_block
      old_options = current_shard_selection.options
      switch_connection(slave: true)
      yield
    ensure
      switch_connection(old_options) if old_options
    end

    def on_cx_switch_block(which, &block)
      @disallow_slave ||= 0
      @disallow_slave += 1 if which == :master

      switch_to_slave = @disallow_slave.zero?
      old_options = current_shard_selection.options

      switch_connection(slave: switch_to_slave)

      # we avoid_readonly_scope to prevent some stack overflow problems, like when
      # .columns calls .with_scope which calls .columns and onward, endlessly.
      if self == ActiveRecord::Base || !switch_to_slave
        yield
      else
        readonly.scoping(&block)
      end
    ensure
      @disallow_slave -= 1 if which == :master
      switch_connection(old_options) if old_options
    end

    def connection_specification_name
      name = current_shard_selection.resolve_connection_name(sharded: is_sharded?, configurations: configurations)

      unless configurations[name] || name == "primary"
        raise ActiveRecord::AdapterNotSpecified, "No database defined by #{name} in your database config. (configurations: #{configurations.inspect})"
      end

      name
    end

    def supports_sharding?
      shard_names.any?
    end

    def on_slave?
      current_shard_selection.on_slave?
    end

    def current_shard_selection
      Thread.current[:shard_selection] ||= ShardSelection.new(shard_names.first)
    end

    def current_shard_id
      current_shard_selection.shard
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

    private

    def switch_connection(options)
      if options.any?
        if options.key?(:shard)
          unless config = configurations[shard_env]
            raise "Did not find #{shard_env} in configurations, did you forget to add it to your database config? (configurations: #{configurations.inspect})"
          end
          unless config['shard_names'].include?(options[:shard])
            raise "Did not find shard #{options[:shard]} in configurations"
          end
          current_shard_selection.shard = options[:shard]
        end

        if options.key?(:slave)
          current_shard_selection.on_slave = options[:slave]
        end

        ensure_shard_connection
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

    def table_exists_with_default_shard?
      with_default_shard { table_exists_without_default_shard? }
    end

    class MasterSlaveProxy
      def initialize(target, which)
        @target = target
        @which = which
      end

      def method_missing(method, *args, &block) # rubocop:disable Style/MethodMissing
        @target.on_master_or_slave(@which) { @target.send(method, *args, &block) }
      end
    end
  end
end

case "#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}"
when '5.0'
  require 'active_record_shards/connection_switcher-5-0'
when '5.1'
  require 'active_record_shards/connection_switcher-5-1'
else
  raise "ActiveRecordShards is not compatible with #{ActiveRecord::VERSION::STRING}"
end
