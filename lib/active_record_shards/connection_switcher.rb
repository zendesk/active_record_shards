# frozen_string_literal: true

require 'active_record_shards/shard_support'

module ActiveRecordShards
  module ConnectionSwitcher
    class LegacyConnectionHandlingError < StandardError; end
    class IsolationLevelError < StandardError; end

    Thread.attr_accessor :_active_record_shards_disallow_replica_by_thread,
                         :_active_record_shards_in_migration,
                         :_active_record_shards_shard_selection

    case "#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}"
    when '6.1', '7.0'
      SHARD_NAMES_CONFIG_KEY = :shard_names
    else
      SHARD_NAMES_CONFIG_KEY = 'shard_names'
    end

    def self.extended(base)
      base.singleton_class.send(:alias_method, :load_schema_without_default_shard!, :load_schema!)
      base.singleton_class.send(:alias_method, :load_schema!, :load_schema_with_default_shard!)

      base.singleton_class.send(:alias_method, :table_exists_without_default_shard?, :table_exists?)
      base.singleton_class.send(:alias_method, :table_exists?, :table_exists_with_default_shard?)

      base.singleton_class.send(:alias_method, :reset_primary_key_without_default_shard, :reset_primary_key)
      base.singleton_class.send(:alias_method, :reset_primary_key, :reset_primary_key_with_default_shard)
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
      self.disallow_replica += 1 if which == :primary

      switch_to_replica = force || disallow_replica.zero?
      old_options = current_shard_selection.options

      switch_connection(replica: switch_to_replica)

      # we avoid_readonly_scope to prevent some stack overflow problems, like when
      # .columns calls .with_scope which calls .columns and onward, endlessly.
      if self == ActiveRecord::Base || !switch_to_replica || construct_ro_scope == false || ActiveRecordShards.disable_replica_readonly_records == true
        yield
      else
        readonly.scoping(&block)
      end
    ensure
      self.disallow_replica -= 1 if which == :primary
      switch_connection(old_options) if old_options
    end

    def disallow_replica=(value)
      Thread.current._active_record_shards_disallow_replica_by_thread = value
    end

    def disallow_replica
      Thread.current._active_record_shards_disallow_replica_by_thread ||= 0
    end

    def supports_sharding?
      shard_names.any?
    end

    def on_replica?
      current_shard_selection.on_replica?
    end

    def current_shard_selection
      Thread.current._active_record_shards_shard_selection ||= ShardSelection.new
    end

    def current_shard_id
      current_shard_selection.shard
    end

    def shard_names
      config_for_env[SHARD_NAMES_CONFIG_KEY] || []
    end

    def reset_primary_key_with_default_shard
      with_default_shard { reset_primary_key_without_default_shard }
    end

    private

    def config_for_env
      @_ars_config_for_env ||= {}
      @_ars_config_for_env[shard_env] ||= begin
        case "#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}"
        when '7.0'
          config = configurations.configs_for(env_name: shard_env, include_hidden: true).first.configuration_hash
        when '6.1'
          config = configurations.configs_for(env_name: shard_env, include_replicas: true).first.configuration_hash
        else
          config = configurations[shard_env]
        end
        unless config
          raise "Did not find #{shard_env} in configurations, did you forget to add it to your database config? (configurations: #{configurations.to_h.keys.inspect})"
        end

        ensure_all_shard_names_are_integers(config)

        config
      end
    end
    alias_method :check_config_for_env, :config_for_env

    def ensure_all_shard_names_are_integers(config)
      unless config.fetch(SHARD_NAMES_CONFIG_KEY, []).all? { |shard_name| shard_name.is_a?(Integer) }
        raise "All shard names must be integers: #{config.inspect}."
      end
    end

    def switch_connection(options)
      ensure_legacy_connection_handling if ActiveRecord.version >= Gem::Version.new('6.1')
      ensure_thread_isolation_level if ActiveRecord.version >= Gem::Version.new('7.0')

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

    def ensure_legacy_connection_handling
      unless legacy_connection_handling_owner.legacy_connection_handling
        raise LegacyConnectionHandlingError, "ActiveRecordShards is _only_ compatible with ActiveRecord `legacy_connection_handling` set to `true`."
      end
    end

    def ensure_thread_isolation_level
      unless ActiveSupport::IsolatedExecutionState.isolation_level == :thread
        raise IsolationLevelError, "ActiveRecordShards is _only_ compatible when ActiveSupport::IsolatedExecutionState's isolation_level is set to :thread"
      end
    end

    def legacy_connection_handling_owner
      @legacy_connection_handling_owner ||=
        case "#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}"
        when '7.0'
          ActiveRecord
        when '6.1'
          ActiveRecord::Base
        end
    end

    def shard_env
      ActiveRecordShards.app_env
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

    def load_schema_with_default_shard!
      with_default_shard { load_schema_without_default_shard! }
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
      ruby2_keywords(:method_missing) if respond_to?(:ruby2_keywords, true)
    end
  end
end

case "#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}"
when '5.1', '5.2'
  require 'active_record_shards/connection_switcher-5-1'
when '6.0'
  require 'active_record_shards/connection_switcher-6-0'
when '6.1'
  require 'active_record_shards/connection_switcher-6-1'
when '7.0'
  require 'active_record_shards/connection_switcher-7-0'
else
  raise "ActiveRecordShards is not compatible with #{ActiveRecord::VERSION::STRING}"
end
