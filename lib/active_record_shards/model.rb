# frozen_string_literal: true

module ActiveRecordShards
  module Model
    def not_sharded
      if self != ActiveRecord::Base && self != base_class
        raise "You should only call not_sharded on direct descendants of ActiveRecord::Base"
      end
      self.sharded = false
    end

    def is_sharded? # rubocop:disable Style/PredicateName
      if self == ActiveRecord::Base
        sharded != false && supports_sharding?
      elsif self == base_class
        if sharded.nil?
          ActiveRecord::Base.is_sharded?
        else
          sharded != false
        end
      else
        base_class.is_sharded?
      end
    end

    def on_slave_by_default?
      if self == ActiveRecord::Base
        false
      elsif self == base_class
        on_slave_by_default
      else
        base_class.on_slave_by_default?
      end
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

    module PrimaryKeyWithDefault
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
      def primary_key
        # Do not call `super`, or it can trigger `stack level too deep` if some
        # code alias_method chain `primay_key` later (e.g. new relic gem)
        @primary_key ||= 'id'
      end
    end

    def self.extended(base)
      base.send(:include, InstanceMethods)
      base.singleton_class.prepend PrimaryKeyWithDefault
      base.after_initialize :initialize_shard_and_slave
    end

    attr_writer :on_slave_by_default

    private

    attr_reader :on_slave_by_default
    attr_accessor :sharded
  end
end
