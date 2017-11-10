module ActiveRecordShards
  module SlaveDb
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

    def on_slave?
      current_slave_selection
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

    def force_cx_switch_slave_block
      old_options = current_slave_selection
      switch_slave_connection(slave: true)
      yield
    ensure
      switch_slave_connection(slave: old_options)
    end

    def on_cx_switch_block(which, &block)
      @disallow_slave ||= 0
      @disallow_slave += 1 if which == :master

      switch_to_slave = @disallow_slave.zero?
      old_options = current_slave_selection

      switch_slave_connection(slave: switch_to_slave)

      # we avoid_readonly_scope to prevent some stack overflow problems, like when
      # .columns calls .with_scope which calls .columns and onward, endlessly.
      if self == ActiveRecord::Base || !switch_to_slave
        yield
      else
        readonly.scoping(&block)
      end
    ensure
      @disallow_slave -= 1 if which == :master
      switch_slave_connection(slave: old_options)
    end

    def current_slave_selection=(on_slave)
      Thread.current[slave_thread_variable_name] = on_slave
    end

    def current_slave_selection
      !!Thread.current[slave_thread_variable_name]
    end

    def connection_config
      super.merge(slave: current_slave_selection)
    end

    def switch_slave_connection(options)
      self.current_slave_selection = options[:slave]
      ensure_shard_connection
    end

    class MasterSlaveProxy
      def initialize(target, which)
        @target = target
        @which = which
      end

      def method_missing(method, *args, &block) # rubocop:disable Style/MethodMissing
        @target.on_master_or_slave(@which) { @target.send(method, *args, &block) }
      end
    end
  end
end
