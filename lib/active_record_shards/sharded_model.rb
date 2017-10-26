module ActiveRecordShards
  module Ext
    module ShardedModel
      def is_sharded? # rubocop:disable Naming/PredicateName
        true
      end
    end
  end

  class ShardedModel < ActiveRecord::Base
    self.abstract_class = true

    extend ActiveRecordShards::Ext::ShardedModel
  end
end
