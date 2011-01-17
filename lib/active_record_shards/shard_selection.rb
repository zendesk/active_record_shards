module ActiveRecordShards
  class ShardSelection
    def initialize
      @on_slave = false
    end

    def shard
      @shard
    end

    def shard=(new_shard)
      @shard = new_shard
    end

    def on_slave?
      @on_slave
    end

    def on_slave=(new_slave)
      @on_slave = (new_slave == true)
    end

    def connection_configuration_name
      shard_name(RAILS_ENV)
    end

    def shard_name(prefix)
      s = ""
      s << prefix.to_s
      if @shard
        s << '_shard_'
        s << @shard.to_s
      end
      s << "_slave" if @on_slave
      s
    end

    def any?
      @on_slave || @shard.present?
    end
  end
end