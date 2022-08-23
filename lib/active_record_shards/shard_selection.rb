# frozen_string_literal: true

module ActiveRecordShards
  class ShardSelection
    NO_SHARD = :_no_shard
    cattr_accessor :ars_default_shard

    def initialize
      @on_replica = false
      @shard = nil
    end

    def shard
      if @shard.nil? || @shard == NO_SHARD
        nil
      else
        @shard || self.class.ars_default_shard
      end
    end

    PRIMARY = "primary"
    def resolve_connection_name(sharded:, configurations:)
      resolved_shard = sharded ? shard : nil
      env = ActiveRecordShards.app_env

      @connection_names ||= {}
      @connection_names[env] ||= {}
      @connection_names[env][resolved_shard] ||= {}
      @connection_names[env][resolved_shard][@on_replica] ||= begin
        name = env.dup
        name << "_shard_#{resolved_shard}" if resolved_shard
        if @on_replica && configurations["#{name}_replica"]
          "#{name}_replica"
        else
          # ActiveRecord always names its default connection pool 'primary'
          # while everything else is named by the configuration name
          resolved_shard ? name : PRIMARY
        end
      end
    end

    def shard=(new_shard)
      @shard = (new_shard || NO_SHARD)
    end

    def on_replica?
      @on_replica
    end

    def on_replica=(new_replica)
      @on_replica = (new_replica == true)
    end

    def options
      { shard: @shard, replica: @on_replica }
    end
  end
end
