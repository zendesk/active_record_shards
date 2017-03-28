# frozen_string_literal: true
module ActiveRecordShards
  module Model
    def not_sharded
      if self != ActiveRecord::Base && self != base_class
        raise "You should only call not_sharded on direct descendants of ActiveRecord::Base"
      end
      @sharded = false
    end

    def is_sharded? # rubocop:disable Style/PredicateName
      sharded_ivar = defined?(@sharded) ? @sharded : nil
      if self == ActiveRecord::Base
        sharded_ivar != false && supports_sharding?
      elsif self == base_class
        if sharded_ivar.nil?
          ActiveRecord::Base.is_sharded?
        else
          sharded_ivar != false
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

    def self.extended(base)
      base.send(:include, InstanceMethods)
      base.after_initialize :initialize_shard_and_slave
    end

    attr_writer :on_slave_by_default

    private

    attr_reader :on_slave_by_default
  end
end
