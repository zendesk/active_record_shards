# frozen_string_literal: true

module ActiveRecordShards
  module Configuration
    def self.shard_id_map
      @shard_id_map ||= {}
    end

    def self.shard_id_map=(shard_id_map)
      @shard_id_map = shard_id_map
    end
  end
end
