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
