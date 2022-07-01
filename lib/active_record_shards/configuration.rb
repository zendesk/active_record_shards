# frozen_string_literal: true

module ActiveRecordShards
  module Configuration
    module_function

    def shard_id_map
      @shard_id_map ||= {}
    end

    def shard_id_map=(shard_id_map)
      @shard_id_map = shard_id_map
    end
  end
end
