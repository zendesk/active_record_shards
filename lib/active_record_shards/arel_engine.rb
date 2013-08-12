if ActiveRecord::VERSION::MAJOR == 3 && ActiveRecord::VERSION::MINOR == 0
  class ActiveRecord::Base
    def self.arel_engine
      @arel_engine ||= begin
        if self == ActiveRecord::Base
          Arel::Table.engine
        else
          connection_handler.connection_pools[connection_pool_name] ? self : superclass.arel_engine
        end
      end
    end
  end
end
