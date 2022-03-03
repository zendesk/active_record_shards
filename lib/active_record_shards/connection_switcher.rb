# frozen_string_literal: true

require 'active_record_shards/shard_support'

module ActiveRecordShards
  module ConnectionSwitcher
    SHARD_NAMES_CONFIG_KEY = 'shard_names'

    def self.extended(base)
      if ActiveRecord::VERSION::MAJOR >= 5
        base.singleton_class.send(:alias_method, :load_schema_without_default_shard!, :load_schema!)
        base.singleton_class.send(:alias_method, :load_schema!, :load_schema_with_default_shard!)
      else
        base.singleton_class.send(:alias_method, :columns_without_default_shard, :columns)
        base.singleton_class.send(:alias_method, :columns, :columns_with_default_shard)
      end

      base.singleton_class.send(:alias_method, :table_exists_without_default_shard?, :table_exists?)
      base.singleton_class.send(:alias_method, :table_exists?, :table_exists_with_default_shard?)
    end

    def default_shard=(new_default_shard)
      ActiveRecordShards::ShardSelection.default_shard = new_default_shard
      switch_connection(shard: new_default_shard)
    end

    def on_primary_db(&block)
      on_shard(nil, &block)
    end

    def on_shard(shard)
      old_options = current_shard_selection.options
      switch_connection(shard: shard) if supports_sharding?
      yield
    ensure
      switch_connection(old_options)
    end

    def on_first_shard(&block)
      shard_name = shard_names.first
      on_shard(shard_name, &block)
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

    def on_replica_if(condition, &block)
      condition ? on_replica(&block) : yield
    end

    def on_replica_unless(condition, &block)
      on_replica_if(!condition, &block)
    end

    def on_primary_if(condition, &block)
      condition ? on_primary(&block) : yield
    end

    def on_primary_unless(condition, &block)
      on_primary_if(!condition, &block)
    end

    def on_primary_or_replica(which, &block)
      if block_given?
        on_cx_switch_block(which, &block)
      else
        PrimaryReplicaProxy.new(self, which)
      end
    end

    # Executes queries using the replica database. Fails over to primary if no replica is found.
    # if you want to execute a block of code on the replica you can go:
    #   Account.on_replica do
    #     Account.first
    #   end
    # the first account will be found on the replica DB
    #
    # For one-liners you can simply do
    #   Account.on_replica.first
    def on_replica(&block)
      on_primary_or_replica(:replica, &block)
    end

    def on_primary(&block)
      on_primary_or_replica(:primary, &block)
    end

    def on_cx_switch_block(which, force: false, construct_ro_scope: nil, &block)
      @disallow_replica ||= 0
      @disallow_replica += 1 if which == :primary

      switch_to_replica = force || @disallow_replica.zero?
      old_options = current_shard_selection.options

      switch_connection(replica: switch_to_replica)

      # we avoid_readonly_scope to prevent some stack overflow problems, like when
      # .columns calls .with_scope which calls .columns and onward, endlessly.
      if self == ActiveRecord::Base || !switch_to_replica || construct_ro_scope == false
        yield
      else
        readonly.scoping(&block)
      end
    ensure
      @disallow_replica -= 1 if which == :primary
      switch_connection(old_options) if old_options
    end

    def supports_sharding?
      shard_names.any?
    end

    def on_replica?
      current_shard_selection.on_replica?
    end

    def current_shard_selection
      Thread.current[:shard_selection] ||= ShardSelection.new
    end

    def current_shard_id
      current_shard_selection.shard
    end

    def shard_names
      unless config_for_env.fetch(SHARD_NAMES_CONFIG_KEY, []).all? { |shard_name| shard_name.is_a?(Integer) }
        raise "All shard names must be integers: #{config_for_env[SHARD_NAMES_CONFIG_KEY].inspect}."
      end

      config_for_env[SHARD_NAMES_CONFIG_KEY] || []
    end

    private

    def config_for_env
      @_ars_config_for_env ||= {}
      @_ars_config_for_env[shard_env] ||= begin
        unless config = configurations[shard_env]
          raise "Did not find #{shard_env} in configurations, did you forget to add it to your database config? (configurations: #{configurations.to_h.keys.inspect})"
        end

        config
      end
    end
    alias_method :check_config_for_env, :config_for_env

    def switch_connection(options)
      if options.any?
        if options.key?(:replica)
          current_shard_selection.on_replica = options[:replica]
        end

        if options.key?(:shard)
          check_config_for_env

          current_shard_selection.shard = options[:shard]
        end

        ensure_shard_connection
      end
    end

    def shard_env
      ActiveRecordShards.rails_env
    end

    # Make these few schema related methods available before having switched to
    # a shard.
    def with_default_shard(&block)
      if is_sharded? && current_shard_id.nil? && table_name != ActiveRecord::SchemaMigration.table_name
        on_first_shard(&block)
      else
        yield
      end
    end

    if ActiveRecord::VERSION::MAJOR >= 5
      def load_schema_with_default_shard!
        with_default_shard { load_schema_without_default_shard! }
      end
    else
      def columns_with_default_shard
        with_default_shard { columns_without_default_shard }
      end
    end

    def table_exists_with_default_shard?
      with_default_shard { table_exists_without_default_shard? }
    end

    class PrimaryReplicaProxy
      def initialize(target, which)
        @target = target
        @which = which
      end

      def method_missing(method, *args, &block) # rubocop:disable Style/MethodMissingSuper, Style/MissingRespondToMissing
        @target.on_primary_or_replica(@which) { @target.send(method, *args, &block) }
      end
    end
  end
end

case "#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}"
when '4.2'
  require 'active_record_shards/connection_switcher-4-2'
when '5.0'
  require 'active_record_shards/connection_switcher-5-0'
when '5.1', '5.2', '6.0'
  require 'active_record_shards/connection_switcher-5-1'
else
  raise "ActiveRecordShards is not compatible with #{ActiveRecord::VERSION::STRING}"
end
