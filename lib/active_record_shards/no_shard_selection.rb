# frozen_string_literal: true
module ActiveRecordShards
  class NoShardSelection
    class NoShardSelected < RuntimeError; end

    def shard
      raise NoShardSelected, "Missing shard information on connection"
    end

    def connection_config
      raise NoShardSelected, "No shard selected, can't connect"
    end
  end
end
