# show which connection was picked to debug master/slave slowness when both servers are the same
module ActiveRecordShards
  module SqlComments
    module Methods
      def execute(query, name = nil)
        slave = ActiveRecord::Base.current_shard_selection.on_slave?
        query += " /* #{slave ? 'slave' : 'master'} */"
        super(query, name)
      end
    end

    def self.enable
      ActiveRecord::Base.on_shard(nil) { ActiveRecord::Base.connection.class.prepend(Methods) }
    end
  end
end
