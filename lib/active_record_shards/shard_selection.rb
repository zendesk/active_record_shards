# frozen_string_literal: true
module ActiveRecordShards
  class ShardSelection
    attr_reader :shard

    def initialize(shard)
      @shard = Integer(shard)
    end

    def connection_config
      { shard: shard }
    end

    def on_shard?
      true
    end
  end
end
