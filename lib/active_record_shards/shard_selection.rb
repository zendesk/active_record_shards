# frozen_string_literal: true
module ActiveRecordShards
  class ShardSelection
    def initialize(shard)
      @on_slave = false
      self.shard = shard
    end

    def shard
      raise "Missing shard information on connection" unless @shard
      @shard
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

    def shard=(new_shard)
      @shard = Integer(new_shard)
    end

    def on_slave?
      @on_slave
    end

    def on_slave=(new_slave)
      @on_slave = (new_slave == true)
    end

    def options
      { shard: @shard, slave: @on_slave }
    end
  end
end
