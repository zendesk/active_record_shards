# frozen_string_literal: true
module ActiveRecordShards
  class ShardSelection
    def initialize(shard)
      self.shard = shard
    end

    def shard
      raise "Missing shard information on connection" unless @shard
      @shard
    end

    def shard=(new_shard)
      @shard = Integer(new_shard)
    end

    def options
      { shard: @shard }
    end
  end
end
