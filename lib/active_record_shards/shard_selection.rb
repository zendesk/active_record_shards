module ActiveRecordShards
  class ShardSelection
    cattr_accessor :default_shard

    def initialize
      @on_slave = false
    end

    def shard(klass = nil)
      if (@shard || self.class.default_shard) && (klass.nil? || klass.is_sharded?)
        (@shard || self.class.default_shard).to_s
      end
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

    def shard_name(klass = nil)
      s = "#{RAILS_ENV}"
      if the_shard = shard(klass)
        s << '_shard_'
        s << the_shard
      end
      s << "_slave" if @on_slave
      s
    end
  end
end