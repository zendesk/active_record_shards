# frozen_string_literal: true
module ActiveRecordShards
  class ShardSelection
    NO_SHARD = :_no_shard
    cattr_accessor :default_shard

    def initialize
      @on_slave = false
    end

    def shard
      if @shard.nil? || @shard == NO_SHARD
        nil
      else
        @shard || self.class.default_shard
      end
    end

    def shard=(new_shard)
      @shard = (new_shard || NO_SHARD)
    end

    def on_slave?
      @on_slave
    end

    def on_slave=(new_slave)
      @on_slave = (new_slave == true)
    end

    PRIMARY = "primary".freeze
    def resolve_connection_name(sharded:, configurations:)
      resolved_shard = sharded ? shard : nil

      if !resolved_shard && !@on_slave
        return PRIMARY
      end

      @shard_names ||= {}
      @shard_names[ActiveRecordShards.rails_env] ||= {}
      @shard_names[ActiveRecordShards.rails_env][resolved_shard] ||= {}
      @shard_names[ActiveRecordShards.rails_env][resolved_shard][@on_slave] ||= begin
        s = ActiveRecordShards.rails_env.dup
        s << "_shard_#{resolved_shard}" if resolved_shard

        if @on_slave && configurations["#{s}_slave"] # fall back to master connection
          s << "_slave"
        end
        s
      end
    end

    def options
      {:shard => @shard, :slave => @on_slave}
    end
  end
end
