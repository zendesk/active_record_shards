module ActiveRecordShards
  class ShardedModel < ActiveRecord::Base
    self.abstract_class = true
  end
end
