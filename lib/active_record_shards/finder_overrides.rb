module ActiveRecordShards
  module FinderOverrides
    SLAVE_METHODS = [ :find_by_sql, :count_by_sql, :calculate ]
    def self.extended(base)
      SLAVE_METHODS.each do |slave_method|
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
    end

    private
    def on_slave_unless_tx(&block)
      if on_slave_by_default? && on_master.connection.open_transactions.zero?
        on_slave { yield }
      else
        yield
      end
    end
  end
end
