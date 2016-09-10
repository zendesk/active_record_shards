# frozen_string_literal: true
module ActiveRecordShards
  class ShardSelection
    NO_SHARD = :_no_shard
    cattr_accessor :default_shard

    def initialize
      @on_slave = false
      @shard = nil
    end

    if ActiveRecord::VERSION::MAJOR < 5

      def shard(klass = nil)
        if (@shard || self.class.default_shard) && (klass.nil? || klass.is_sharded?)
          if @shard == NO_SHARD
            nil
          else
            @shard || self.class.default_shard
          end
        end
      end

      def shard_name(klass = nil, try_slave = true)
        the_shard = shard(klass)

        @shard_names ||= {}
        @shard_names[ActiveRecordShards.rails_env] ||= {}
        @shard_names[ActiveRecordShards.rails_env][the_shard] ||= {}
        @shard_names[ActiveRecordShards.rails_env][the_shard][try_slave] ||= {}
        @shard_names[ActiveRecordShards.rails_env][the_shard][try_slave][@on_slave] ||= begin
          s = ActiveRecordShards.rails_env.dup
          s << "_shard_#{the_shard}" if the_shard
          s << "_slave"              if @on_slave && try_slave
          s
        end
      end

    else

      def shard
        if @shard.nil? || @shard == NO_SHARD
          nil
        else
          @shard || self.class.default_shard
        end
      end

      PRIMARY = "primary".freeze
      def resolve_connection_name(sharded:, configurations:)
        resolved_shard = sharded ? shard : nil

        if !resolved_shard && !@on_slave
          return PRIMARY
        end

        @shard_names ||= {}
        @shard_names[ActiveRecordShards.rails_env] ||= {}
        @shard_names[ActiveRecordShards.rails_env][resolved_shard] ||= {}
        @shard_names[ActiveRecordShards.rails_env][resolved_shard][@on_slave] ||= begin
          s = ActiveRecordShards.rails_env.dup
          s << "_shard_#{resolved_shard}" if resolved_shard

          if @on_slave && configurations["#{s}_slave"] # fall back to master connection
            s << "_slave"
          end
          s
        end
      end

    end

    def shard=(new_shard)
      @shard = (new_shard || NO_SHARD)
    end

    def on_slave?
      @on_slave
    end

    def on_slave=(new_slave)
      @on_slave = (new_slave == true)
    end

    def options
      { shard: @shard, slave: @on_slave }
    end
  end
end
