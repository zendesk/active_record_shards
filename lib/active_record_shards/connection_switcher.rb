# frozen_string_literal: true

require_relative 'configuration'

module ActiveRecordShards
  module ConnectionSwitcher
    SHARD_NAMES_CONFIG_KEY = 'shard_names'

    def default_shard=(new_default_shard)
      ActiveRecordShards::ShardSelection.default_shard = new_default_shard
      switch_connection(shard: new_default_shard)
    end

    def on_primary_db(&block)
      on_shard(:default, &block)
    end

    def on_shard(shard)
      old_shard = ars_current_shard
      shard = :default if shard.nil?
      self.ars_current_shard = shard
      yield
    ensure
      self.ars_current_shard = old_shard
    end

    def on_first_shard(&block)
      shard_name = shard_names.first
      on_shard(shard_name, &block)
    end

    def on_all_shards
      if supports_sharding?
        shard_names.map do |shard|
          on_shard(shard) do
            yield(shard)
          end
        end
      else
        [yield]
      end
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
      if block_given?
        ActiveRecord::Base.connected_to(role: :reading, &block)
      else
        PrimaryReplicaProxy.new(self, :replica)
      end
    end

    def on_primary(&block)
      on_primary_or_replica(:primary, &block)
    end

    def on_cx_switch_block(which, &block)
      case which
      when :primary
        ActiveRecord::Base.connected_to(role: :writing, &block)
      when :replica
        ActiveRecord::Base.connected_to(role: :reading, &block)
      else
        raise
      end
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
      @shard_names ||= ActiveRecordShards::Configuration.shard_id_map.keys
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

    def ensure_shard_connection
      # See if we've connected before. If not, call `#establish_connection`
      # so that ActiveRecord can resolve connection_specification_name to an
      # ARS connection.
      spec_name = connection_specification_name

      pool = connection_handler.retrieve_connection_pool(spec_name)
      connection_handler.establish_connection(spec_name.to_sym) if pool.nil?
    end

    def shard_env
      ActiveRecordShards.app_env
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
