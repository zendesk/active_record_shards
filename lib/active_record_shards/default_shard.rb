# frozen_string_literal: true

module ActiveRecordShards
  module DefaultShard
    def default_shard=(new_default_shard)
      if ars_shard_type?(new_default_shard)
        ActiveRecordShards::ShardSelection.ars_default_shard = new_default_shard
        switch_connection(shard: new_default_shard)
      else
        super
      end
    end

    private

    def ars_shard_type?(shard)
      return true if ActiveRecord.version < Gem::Version.new("6.1")
      return true if shard.nil?
      return true if shard == :_no_shard
      return true if shard.is_a?(Integer)

      false
    end
  end
end

ActiveRecord::Base.singleton_class.prepend(ActiveRecordShards::DefaultShard)
