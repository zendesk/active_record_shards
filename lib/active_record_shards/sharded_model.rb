module ActiveRecordShards
  module Ext
    module ShardedModel
      def self.extended(base)
        base.extend(ActiveRecordShards::ConnectionSwitcher)
        base.include(InstanceMethods)
        base.after_initialize :initialize_shard
      end

      def is_sharded? # rubocop:disable Naming/PredicateName
        true
      end

      module InstanceMethods
        def initialize_shard
          @from_shard = self.class.current_shard_selection.shard
        end

        def from_shard
          @from_shard
        end
      end
    end
  end

  class ShardedModel < ActiveRecord::Base
    self.abstract_class = true

    extend ActiveRecordShards::Ext::ShardedModel
  end
end
