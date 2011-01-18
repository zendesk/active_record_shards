module ActiveRecordShards
  module Model
    def not_sharded
      if self == ActiveRecord::Base || self != base_class
        raise "You should only call not_sharded on direct descendants of ActiveRecord::Base"
      end
      @sharded = false
    end

    def is_sharded?
      if self == ActiveRecord::Base
        true
      elsif self == base_class
        @sharded != false
      else
        base_class.is_sharded?
      end
    end
  end
end