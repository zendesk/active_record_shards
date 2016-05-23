# frozen_string_literal: true
module ActiveRecordShards
  class ShardSelection
    NO_SHARD = :_no_shard
    cattr_accessor :default_shard

    def initialize
      @on_slave = false
    end

    def shard(klass = nil)
      if (@shard || self.class.default_shard) && (klass.nil? || klass.is_sharded?)
        if @shard == NO_SHARD
          nil
        else
          @shard || self.class.default_shard
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

    def shard_name(klass = nil, try_slave = true)
      the_shard = shard(klass)

      if !the_shard && (!@on_slave && try_slave)
        return "primary"
      end

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

    def options
      {:shard => @shard, :slave => @on_slave}
    end
  end
end
