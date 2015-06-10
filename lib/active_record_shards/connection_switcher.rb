require 'active_record_shards/shard_support'

module ActiveRecordShards
  module ConnectionSwitcher
    def self.extended(klass)
      klass.singleton_class.alias_method_chain :columns, :default_shard
      klass.singleton_class.alias_method_chain :table_exists?, :default_shard
    end

    def default_shard=(new_default_shard)
      ActiveRecordShards::ShardSelection.default_shard = new_default_shard
      switch_connection(shard: new_default_shard)
    end

    def on_shard(shard, &block)
      old_options = current_shard_selection.options
      switch_connection(shard: shard) if supports_sharding?
      yield
    ensure
      switch_connection(old_options)
    end

    def on_first_shard(&block)
      shard_name = shard_names.first
      on_shard(shard_name) { yield }
    end

    def shards
      ShardSupport.new(self == ActiveRecord::Base ? nil : where(nil))
    end

    def on_all_shards(&block)
      old_options = current_shard_selection.options
      if supports_sharding?
        shard_names.map do |shard|
          switch_connection(shard: shard)
          yield(shard)
        end
      else
        [yield]
      end
    ensure
      switch_connection(old_options)
    end

    def on_slave_if(condition, &block)
      condition ? on_slave(&block) : yield
    end

    def on_slave_unless(condition, &block)
      on_slave_if(!condition, &block)
    end

    def on_master_if(condition, &block)
      condition ? on_master(&block) : yield
    end

    def on_master_unless(condition, &block)
      on_master_if(!condition, &block)
    end

    def on_master_or_slave(which, &block)
      if block_given?
        on_cx_switch_block(which, &block)
      else
        MasterSlaveProxy.new(self, which)
      end
   end

    # Executes queries using the slave database. Fails over to master if no slave is found.
    # if you want to execute a block of code on the slave you can go:
    #   Account.on_slave do
    #     Account.first
    #   end
    # the first account will be found on the slave DB
    #
    # For one-liners you can simply do
    #   Account.on_slave.first
    def on_slave(&block)
      on_master_or_slave(:slave, &block)
    end

    def on_master(&block)
      on_master_or_slave(:master, &block)
    end

    # just to ease the transition from replica to active_record_shards
    alias_method :with_slave, :on_slave
    alias_method :with_slave_if, :on_slave_if
    alias_method :with_slave_unless, :on_slave_unless

    def on_cx_switch_block(which, options = {}, &block)
      old_options = current_shard_selection.options
      switch_to_slave = (which == :slave && (@disallow_slave.nil? || @disallow_slave == 0))
      switch_connection(slave: switch_to_slave)

      @disallow_slave = (@disallow_slave || 0) + 1 if which == :master

      # we avoid_readonly_scope to prevent some stack overflow problems, like when
      # .columns calls .with_scope which calls .columns and onward, endlessly.
      if self == ActiveRecord::Base || !switch_to_slave || options[:construct_ro_scope] == false
        yield
      else
        readonly.scoping(&block)
      end
    ensure
      @disallow_slave -= 1 if which == :master
      switch_connection(old_options)
    end

    # Name of the connection pool. Used by ConnectionHandler to retrieve the current connection pool.
    def connection_pool_name # :nodoc:
      name = @connection_pool_name_override || current_shard_selection.shard_name(self)

      if configurations[name].nil? && on_slave?
        current_shard_selection.shard_name(self, false)
      else
        name
      end
    end

    def establish_connection_override(connection_name)
      @connection_pool_name_override = connection_name
      establish_connection(connection_name)
    end

    def supports_sharding?
      shard_names.any?
    end

    def on_slave?
      current_shard_selection.on_slave?
    end

    def current_shard_selection
      Thread.current[:shard_selection] ||= ShardSelection.new
    end

    def current_shard_id
      current_shard_selection.shard
    end

    def shard_names
      unless config = configurations[shard_env]
        raise "Did not find #{shard_env} in configurations, did you forget to add it to your database.yml ? (configurations: #{configurations.inspect})"
      end
      config['shard_names'] || []
    end

    private

    def switch_connection(options)
      if options.any?
        if options.has_key?(:slave)
          current_shard_selection.on_slave = options[:slave]
        end

        if options.has_key?(:shard)
          current_shard_selection.shard = options[:shard]
        end

        establish_shard_connection unless connected_to_shard?
      end
    end

    def shard_env
      ActiveRecordShards.rails_env
    end

    def establish_shard_connection
      name = connection_pool_name
      spec = configurations[name]

      raise ActiveRecord::AdapterNotSpecified.new("No database defined by #{name} in database.yml") if spec.nil?

      # in 3.2 rails is asking for a connection pool in a map of these ConnectionSpecifications.  If we want to re-use connections,
      # we need to re-use specs.

      # note that since we're subverting the standard establish_connection path, we have to handle the funky autoloading of the
      # connection adapter ourselves.
      specification_cache[name] ||= begin
        if ActiveRecord::VERSION::MAJOR == 4 && ActiveRecord::VERSION::MINOR >= 1
          resolver = ActiveRecordShards::ConnectionSpecification::Resolver.new configurations
          resolver.spec(spec)
        else
          resolver = ActiveRecordShards::ConnectionSpecification::Resolver.new spec, configurations
          resolver.spec
        end
      end

      if ActiveRecord::VERSION::MAJOR >= 4
        connection_handler.establish_connection(self, specification_cache[name])
      else
        connection_handler.establish_connection(connection_pool_name, specification_cache[name])
      end
    end

    def specification_cache
      @@specification_cache ||= {}
    end

    def connection_pool_key
      specification_cache[connection_pool_name]
    end

    def connected_to_shard?
      if ActiveRecord::VERSION::MAJOR >= 4
        specs_to_pools = Hash[connection_handler.connection_pool_list.map { |pool| [pool.spec, pool] }]
      else
        specs_to_pools = connection_handler.connection_pools
      end

      specs_to_pools.has_key?(connection_pool_key)
    end

    def columns_with_default_shard
      if is_sharded? && current_shard_id.nil? && table_name != ActiveRecord::Migrator.schema_migrations_table_name
        on_first_shard { columns_without_default_shard }
      else
        columns_without_default_shard
      end
    end

    def table_exists_with_default_shard?
      result = table_exists_without_default_shard?

      if !result && is_sharded? && (shard_name = shard_names.first)
        result = on_shard(shard_name) { table_exists_without_default_shard? }
      end

      result
    end

    def autoload_adapter(adapter_name)
      begin
        require 'rubygems'
        gem "activerecord-#{adapter_name}-adapter"
        require "active_record/connection_adapters/#{adapter_name}_adapter"
      rescue LoadError
        begin
          require "active_record/connection_adapters/#{adapter_name}_adapter"
        rescue LoadError
          raise "Please install the #{adapter_name} adapter: `gem install activerecord-#{adapter_name}-adapter` (#{$!})"
        end
      end

      adapter_method = "#{adapter_name}_connection"
      if !ActiveRecord::Base.respond_to?(adapter_name + "_connection")
        raise AdapterNotFound, "database configuration specifies nonexistent #{adapter_name} adapter"
      end
    end

    class MasterSlaveProxy
      def initialize(target, which)
        @target = target
        @which = which
      end

      def method_missing(method, *args, &block)
        @target.on_master_or_slave(@which) { @target.send(method, *args, &block) }
      end
    end
  end
end
