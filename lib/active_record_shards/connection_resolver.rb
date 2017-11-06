module ActiveRecordShards
  class ConnectionResolver
    attr_reader :configurations

    def initialize(configurations)
      @configurations = configurations
    end

    PRIMARY = "primary".freeze
    def resolve_connection_name(slave:, shard:, sharded:)
      resolved_shard = sharded ? shard : nil

      if !resolved_shard && !slave
        return PRIMARY
      end

      @shard_names ||= {}
      @shard_names[ActiveRecordShards.rails_env] ||= {}
      @shard_names[ActiveRecordShards.rails_env][resolved_shard] ||= {}
      @shard_names[ActiveRecordShards.rails_env][resolved_shard][slave] ||= begin
        s = ActiveRecordShards.rails_env.dup
        s << "_shard_#{resolved_shard}" if resolved_shard

        if slave && configurations["#{s}_slave"] # fall back to master connection
          s << "_slave"
        end
        s
      end
    end
  end
end
