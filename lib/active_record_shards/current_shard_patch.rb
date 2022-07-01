# frozen_string_literal: true

module ActiveRecordShards
  module CurrentShardPatch
    cattr_accessor :ars_current_shard

    def current_shard
      return :default unless is_sharded?
      return :default if ActiveRecord::Base.ars_current_shard == :default

      new_shard = if ars_current_shard.nil?
                    super
                  else
                    ars_current_shard
                  end
      return :default if new_shard == :default || new_shard.nil?

      ActiveRecordShards::Configuration.shard_id_map.fetch(new_shard.to_i)
    end
  end
end
