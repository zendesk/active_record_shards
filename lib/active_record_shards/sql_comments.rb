# show which connection was picked to debug primary/replica slowness when both servers are the same
module ActiveRecordShards
  module SqlComments
    module Methods
      def execute(query, name = nil)
        replica = ActiveRecord::Base.current_shard_selection.on_replica?
        query += " /* #{replica ? 'replica' : 'primary'} */"
        super(query, name)
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
