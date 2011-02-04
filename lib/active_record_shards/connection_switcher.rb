module ActiveRecordShards
  module ConnectionSwitcher
    def default_shard=(new_default_shard)
      ActiveRecordShards::ShardSelection.default_shard = new_default_shard
      switch_connection(:shard => new_default_shard)
    end

    def on_shard(shard, &block)
      old_shard = current_shard_selection.shard
      switch_connection(:shard => shard)
      yield
    ensure
      switch_connection(:shard => old_shard)
    end

    def on_all_shards(&block)
        old_shard = current_shard_selection.shard
        shard_names.each do |shard|
          switch_connection(:shard => shard)
          yield
        end
      ensure
        switch_connection(:shard => old_shard)
    end

    def on_slave_if(condition, &block)
      condition ? on_slave(&block) : yield
    end

    def on_slave_unless(condition, &block)
      on_slave_if(!condition, &block)
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
      if block_given?
        on_slave_block(&block)
      else
        SlaveProxy.new(self)
      end
    end

    # just to ease the transition from replica to active_record_shards
    alias_method :with_slave, :on_slave
    alias_method :with_slave_if, :on_slave_if
    alias_method :with_slave_unless, :on_slave_unless

    def on_slave_block(&block)
      old_slave = current_shard_selection.on_slave?
      begin
        switch_connection(:slave => true)
      rescue ActiveRecord::AdapterNotSpecified => e
        switch_connection(:slave => old_slave)
        logger.warn("Failed to establish shard connection: #{e.message} - defaulting to master")
      end
      with_scope({:find => {:readonly => current_shard_selection.on_slave?}}, :merge, &block)
    ensure
      switch_connection(:slave => old_slave)
    end

    # Name of the connection pool. Used by ConnectionHandler to retrieve the current connection pool.
    def connection_pool_name # :nodoc:
      current_shard_selection.shard_name(self)
    end

    private

    def current_shard_selection
      Thread.current[:shard_selection] ||= ShardSelection.new
    end

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

    def shard_names
      env_name = defined?(Rails.env) ? Rails.env : RAILS_ENV
      configurations[env_name]['shard_names']
    end

    def establish_shard_connection
      name = current_shard_selection.shard_name(self)
      spec = configurations[name]
      raise ActiveRecord::AdapterNotSpecified.new("No database defined by #{name} in database.yml") if spec.nil?

      connection_handler.establish_connection(connection_pool_name, ActiveRecord::Base::ConnectionSpecification.new(spec, "#{spec['adapter']}_connection"))
    end

    def connected_to_shard?
      connection_handler.connection_pools.has_key?(connection_pool_name)
    end

    class SlaveProxy
      def initialize(target)
        @target = target
      end

      def method_missing(method, *args, &block)
        @target.on_slave_block { @target.send(method, *args, &block) }
      end
    end
  end
end
