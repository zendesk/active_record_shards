# frozen_string_literal: true
require 'active_record_shards/shard_support'

# we share a single schema-cache across all connections, so columns etc queries get cached
# this is safe as long as all connections have the same schema
# also replaces the connection so we do not leave a possibly stale connection behind
# TODO: make this the slave connections schema_cache for even more savings
module ActiveRecordShards
  module ConnectionSchemaCache
    def connection
      c = super
      @schema_cache ||= c.schema_cache
      @schema_cache.instance_variable_set(:@connection, c)
      c.instance_variable_set(:@schema_cache, @schema_cache)
      c
    end
  end
end
