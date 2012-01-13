module ActiveRecordShards
  module FinderOverrides
    CLASS_SLAVE_METHODS = [ :find_by_sql, :count_by_sql, :calculate, :find_one, :find_some, :find_every, :quote_value ]

    def self.extended(base)
      CLASS_SLAVE_METHODS.each do |slave_method|
        base.class_eval <<-EOF, __FILE__, __LINE__ + 1
          class <<self
            def #{slave_method}_with_slave_by_default(*args, &block)
              on_slave_unless_tx do
                #{slave_method}_without_slave_by_default(*args, &block)
              end
            end

            alias_method_chain :#{slave_method}, :slave_by_default
          end
        EOF
      end

      base.class_eval do
        # fix ActiveRecord to do the right thing, and use our aliased quote_value
        def quote_value(*args, &block)
          self.class.quote_value(*args, &block)
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
    end

    def on_slave_unless_tx(&block)
      if on_slave_by_default? && !Thread.current[:_active_record_shards_slave_off]
        on_slave { yield }
      else
        yield
      end
    end
  end
end
