module ActiveRecordShards
  module DefaultSlavePatches
    def self.wrap_method_in_on_slave(class_method, base, method)

      if class_method
        base_methods = (base.methods | base.private_methods).map(&:to_sym)
      else
        base_methods = (base.instance_methods | base.private_instance_methods).map(&:to_sym)
      end

      return unless base_methods.include?(method)
      _, method, punctuation = method.to_s.match(/^(.*?)([\?\!]?)$/).to_a
      base.class_eval <<-RUBY, __FILE__, __LINE__ + 1
        #{class_method ? "class << self" : ""}
          def #{method}_with_default_slave#{punctuation}(*args, &block)
            on_slave_unless_tx do
              #{method}_without_default_slave#{punctuation}(*args, &block)
            end
          end

          alias_method_chain :#{method}#{punctuation}, :default_slave
        #{class_method ? "end" : ""}
      RUBY
    end

    CLASS_SLAVE_METHODS = [ :find_by_sql, :count_by_sql,  :calculate, :find_one, :find_some, :find_every, :quote_value, :sanitize_sql_hash_for_conditions, :exists?, :table_exists? ]

    def self.extended(base)
      CLASS_SLAVE_METHODS.each { |m| ActiveRecordShards::DefaultSlavePatches.wrap_method_in_on_slave(true, base, m) }

      base.class_eval do
        # fix ActiveRecord to do the right thing, and use our aliased quote_value
        def quote_value(*args, &block)
          self.class.quote_value(*args, &block)
        end

        def reload_with_slave_off(*args, &block)
          self.class.on_master { reload_without_slave_off(*args, &block) }
        end
        alias_method_chain :reload, :slave_off

        class << self
          def columns_with_default_slave(*args, &block)
            if on_slave_by_default? && !Thread.current[:_active_record_shards_slave_off]
              read_columns_from = :slave
            else
              read_columns_form = :master
            end

            on_cx_switch_block(read_columns_from, :construct_ro_scope => false) { columns_without_default_slave(*args, &block) }
          end
          alias_method_chain :columns, :default_slave
        end

        class << self
          def transaction_with_slave_off(*args, &block)
            if on_slave_by_default?
              old_val = Thread.current[:_active_record_shards_slave_off]
              Thread.current[:_active_record_shards_slave_off] = true
            end

            transaction_without_slave_off(*args, &block)
          ensure
            if on_slave_by_default?
              Thread.current[:_active_record_shards_slave_off] = old_val
            end
          end

          alias_method_chain :transaction, :slave_off
        end
      end
      ActiveRecordShards::DefaultSlavePatches.wrap_method_in_on_slave(false, ActiveRecord::Associations::HasAndBelongsToManyAssociation, :construct_sql)
      ActiveRecordShards::DefaultSlavePatches.wrap_method_in_on_slave(false, ActiveRecord::Associations::HasAndBelongsToManyAssociation, :construct_find_options!)
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
      def self.included(base)
        ActiveRecordShards::DefaultSlavePatches.wrap_method_in_on_slave(false, base, :records_for) rescue nil
      end

      def on_slave_unless_tx
        klass.on_slave_unless_tx { yield }
      end

      def exists_with_default_slave?(*args, &block)
        on_slave_unless_tx { exists_without_default_slave?(*args, &block) }
      end
    end
  end
end
