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

      PRIMARY = "primary"
      def resolve_connection_name(sharded:, configurations:)
        resolved_shard = sharded ? shard : nil
        env = ActiveRecordShards.rails_env

        @connection_names ||= {}
        @connection_names[env] ||= {}
        @connection_names[env][resolved_shard] ||= {}
        @connection_names[env][resolved_shard][@on_slave] ||= begin
          name = env.dup
          name << "_shard_#{resolved_shard}" if resolved_shard
          if @on_slave && configurations["#{name}_slave"]
            "#{name}_slave"
          else
            # ActiveRecord always names its default connection pool 'primary'
            # while everything else is named by the configuration name
            resolved_shard ? name : PRIMARY
          end
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
