# show which connection was picked to debug primary/replica slowness when both servers are the same
module ActiveRecordShards
  module SqlComments
    module Methods
      def execute(query, name = nil, **kwargs)
        shard = ActiveRecord::Base.current_shard_selection.shard
        shard_text = shard ? "shard #{shard}" : 'unsharded'
        replica = ActiveRecord::Base.current_shard_selection.on_replica?
        replica_text = replica ? 'replica' : 'primary'
        query = "/* #{shard_text} #{replica_text} */ " + query
        super(query, name, **kwargs)
      end
    end

    def self.enable
      ActiveRecord::Base.on_replica do
        ActiveRecord::Base.on_shard(nil) do
          ActiveRecord::Base.connection.class.prepend(Methods)
        end
      end
    end
  end
end
