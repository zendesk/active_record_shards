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
          (@shard || self.class.default_shard).to_s
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
      s = "#{RAILS_ENV}"
      if the_shard = shard(klass)
        s << '_shard_'
        s << the_shard
      end
      if @on_slave && try_slave
        s << "_slave" if @on_slave
      end
      s
    end

    def options
      {:shard => @shard, :slave => @on_slave}
    end
  end
end