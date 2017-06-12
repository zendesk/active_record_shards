# frozen_string_literal: true
module ActiveRecordShards
  module Model
    def not_sharded
      if self != ActiveRecord::Base && self != base_class
        raise "You should only call not_sharded on direct descendants of ActiveRecord::Base"
      end
      @sharded = false
    end

    def is_sharded?
      if self == ActiveRecord::Base
        @sharded != false && supports_sharding?
      elsif self == base_class
        if @sharded.nil?
          ActiveRecord::Base.is_sharded?
        else
          @sharded != false
        end
      else
        base_class.is_sharded?
      end
    end

    def on_slave_by_default?
      if self == ActiveRecord::Base
        false
      elsif self == base_class
        @on_slave_by_default
      else
        base_class.on_slave_by_default?
      end
    end

    def on_slave_by_default=(val)
      @on_slave_by_default = val
    end

    module InstanceMethods
      def initialize_shard_and_slave
        @from_slave = !!self.class.current_shard_selection.options[:slave]
        @from_shard = self.class.current_shard_selection.options[:shard]
      end

      def from_slave?
        @from_slave
      end

      def from_shard
        @from_shard
      end
    end

    def self.extended(base)
      base.send(:include, InstanceMethods)
      base.singleton_class.send(:alias_method, :primary_key_without_default_value, :primary_key)
      base.singleton_class.send(:alias_method, :primary_key, :primary_key_with_default_value)
      base.after_initialize :initialize_shard_and_slave
    end


    # In a shared connection, ShardedModel.table_exists? will run on the first
    # shard (because of ConnectionSwitcher#table_exists_with_default_shard), while
    # ShardedModel.connection.table_exists?(sharded_table) will still run on the
    # *shared* connection (and will return false, as the sharded table doesn't exist
    # in the shared database). Among other potential issues, this behavior causes
    # ActiveRecord to cache the sharded table primary_id as nil.
    #
    # Removing the with_default_shard behavior might cause issues, so instead
    # we set primary_key as 'id'. Any model with a different primary key will
    # need to explicit set it in the class definition.
    def primary_key_with_default_value
      @primary_key = 'id' unless defined? @primary_key
      primary_key_without_default_value
    end
  end
end
