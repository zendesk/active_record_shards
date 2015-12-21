module ActiveRecordShards
  module DefaultSlavePatches
    def self.wrap_method_in_on_slave(class_method, base, method)

      if class_method
        base_methods = (base.methods | base.private_methods).map(&:to_sym)
      else
        base_methods = (base.instance_methods | base.private_instance_methods).map(&:to_sym)
      end

      return unless base_methods.include?(method)
      injected_module = Module.new
      injected_module.send(:define_method, method) do |*args, &block|
        on_slave_unless_tx do
          super(*args, &block)
        end
      end
      (class_method ? base.singleton_class : base).send(:prepend, injected_module)
    end

    CLASS_SLAVE_METHODS = [ :find_by_sql, :count_by_sql,  :calculate, :find_one, :find_some, :find_every, :quote_value, :sanitize_sql_hash_for_conditions, :exists?, :table_exists? ]

    module PrependClassMethods
      def columns
        if on_slave_by_default? && !Thread.current[:_active_record_shards_slave_off]
          read_columns_from = :slave
        else
          read_columns_form = :master
        end

        on_cx_switch_block(read_columns_from, construct_ro_scope: false) { super }
      end

      def transaction(*args, &block)
        if on_slave_by_default?
          old_val = Thread.current[:_active_record_shards_slave_off]
          Thread.current[:_active_record_shards_slave_off] = true
        end

        super(*args, &block)
      ensure
        if on_slave_by_default?
          Thread.current[:_active_record_shards_slave_off] = old_val
        end
      end
    end

    module PrependMethods
      # fix ActiveRecord to do the right thing, and use our aliased quote_value
      def quote_value(*args, &block)
        self.class.quote_value(*args, &block)
      end

      def reload(*args, &block)
        self.class.on_master { super(*args, &block) }
      end
    end

    def self.extended(base)
      base.send(:prepend, PrependMethods)
      base.singleton_class.send(:prepend, PrependClassMethods)

      CLASS_SLAVE_METHODS.each { |m| ActiveRecordShards::DefaultSlavePatches.wrap_method_in_on_slave(true, base, m) }

      if ActiveRecord::Associations.const_defined?(:HasAndBelongsToManyAssociation)
        ActiveRecordShards::DefaultSlavePatches.wrap_method_in_on_slave(false, ActiveRecord::Associations::HasAndBelongsToManyAssociation, :construct_sql)
        ActiveRecordShards::DefaultSlavePatches.wrap_method_in_on_slave(false, ActiveRecord::Associations::HasAndBelongsToManyAssociation, :construct_find_options!)
      end
    end

    def on_slave_unless_tx(&block)
      if on_slave_by_default? && !Thread.current[:_active_record_shards_slave_off]
        on_slave { yield }
      else
        yield
      end
    end

    module ActiveRelationPatches
      def self.included(base)
        ActiveRecordShards::DefaultSlavePatches.wrap_method_in_on_slave(false, base, :calculate)
        ActiveRecordShards::DefaultSlavePatches.wrap_method_in_on_slave(false, base, :exists?)
        ActiveRecordShards::DefaultSlavePatches.wrap_method_in_on_slave(false, base, :pluck)
      end

      def on_slave_unless_tx
        @klass.on_slave_unless_tx { yield }
      end
    end

    module HasAndBelongsToManyPreloaderPatches
      def self.prepended(base)
        ActiveRecordShards::DefaultSlavePatches.wrap_method_in_on_slave(false, base, :records_for) rescue nil
      end

      def on_slave_unless_tx
        klass.on_slave_unless_tx { yield }
      end

      def exists?(*args, &block)
        on_slave_unless_tx { super(*args, &block) }
      end
    end

    # in rails 4.1+, they create a join class that's used to pull in records for HABTM.
    # this simplifies the hell out of our existence, because all we have to do is inerit on-slave-by-default
    # down from the parent now.
    module Rails41HasAndBelongsToManyBuilderExtension
      def through_model
        model = super
        def model.on_slave_by_default?
          left_reflection.klass.on_slave_by_default?
        end

        # also transfer the sharded-ness of the left table to the join model
        model.not_sharded if !model.left_reflection.klass.is_sharded?
        model
      end
    end
  end
end
