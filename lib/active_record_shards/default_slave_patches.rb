# frozen_string_literal: true
module ActiveRecordShards
  module DefaultSlavePatches
    def self.wrap_method_in_on_slave(class_method, base, method)
      base_methods =
        if class_method
          base.methods + base.private_methods
        else
          base.instance_methods + base.private_instance_methods
        end

      return unless base_methods.include?(method)
      _, method, punctuation = method.to_s.match(/^(.*?)([\?\!]?)$/).to_a
      base.class_eval <<-RUBY, __FILE__, __LINE__ + 1
        #{class_method ? 'class << self' : ''}
          def #{method}_with_default_slave#{punctuation}(*args, &block)
            on_slave_unless_tx do
              #{method}_without_default_slave#{punctuation}(*args, &block)
            end
          end

          alias_method :#{method}_without_default_slave#{punctuation}, :#{method}#{punctuation}
          alias_method :#{method}#{punctuation}, :#{method}_with_default_slave#{punctuation}
        #{class_method ? 'end' : ''}
      RUBY
    end

    def columns_with_default_slave(*args, &block)
      read_columns_from =
        if on_slave_by_default? && !Thread.current[:_active_record_shards_slave_off]
          :slave
        else
          :master
        end

      on_cx_switch_block(read_columns_from, construct_ro_scope: false) { columns_without_default_slave(*args, &block) }
    end

    def transaction_with_slave_off(*args, &block)
      if on_slave_by_default?
        begin
          old_val = Thread.current[:_active_record_shards_slave_off]
          Thread.current[:_active_record_shards_slave_off] = true
          transaction_without_slave_off(*args, &block)
        ensure
          Thread.current[:_active_record_shards_slave_off] = old_val
        end
      else
        transaction_without_slave_off(*args, &block)
      end
    end

    module InstanceMethods
      # fix ActiveRecord to do the right thing, and use our aliased quote_value
      def quote_value(*args, &block)
        self.class.quote_value(*args, &block)
      end

      def reload_with_slave_off(*args, &block)
        self.class.on_master { reload_without_slave_off(*args, &block) }
      end
    end

    CLASS_SLAVE_METHODS = [:find_by_sql, :count_by_sql, :calculate, :find_one, :find_some, :find_every, :exists?, :table_exists?].freeze

    def self.extended(base)
      CLASS_SLAVE_METHODS.each { |m| ActiveRecordShards::DefaultSlavePatches.wrap_method_in_on_slave(true, base, m) }

      base.class_eval do
        include InstanceMethods

        alias_method :reload_without_slave_off, :reload
        alias_method :reload, :reload_with_slave_off

        class << self
          alias_method :columns_without_default_slave, :columns
          alias_method :columns, :columns_with_default_slave

          alias_method :transaction_without_slave_off, :transaction
          alias_method :transaction, :transaction_with_slave_off
        end
      end
      if ActiveRecord::Associations.const_defined?(:HasAndBelongsToManyAssociation)
        ActiveRecordShards::DefaultSlavePatches.wrap_method_in_on_slave(false, ActiveRecord::Associations::HasAndBelongsToManyAssociation, :construct_sql)
        ActiveRecordShards::DefaultSlavePatches.wrap_method_in_on_slave(false, ActiveRecord::Associations::HasAndBelongsToManyAssociation, :construct_find_options!)
      end
    end

    def on_slave_unless_tx
      if on_slave_by_default? && !Thread.current[:_active_record_shards_slave_off]
        on_slave { yield }
      else
        yield
      end
    end

    module ActiveRelationPatches
      def self.included(base)
        [:calculate, :exists?, :pluck, :find_with_associations].each do |m|
          ActiveRecordShards::DefaultSlavePatches.wrap_method_in_on_slave(false, base, m)
        end
      end

      def on_slave_unless_tx
        @klass.on_slave_unless_tx { yield }
      end
    end

    module HasAndBelongsToManyPreloaderPatches
      def self.included(base)
        ActiveRecordShards::DefaultSlavePatches.wrap_method_in_on_slave(false, base, :records_for) rescue nil # rubocop:disable Style/RescueModifier
      end

      def on_slave_unless_tx
        klass.on_slave_unless_tx { yield }
      end

      def exists_with_default_slave?(*args, &block)
        on_slave_unless_tx { exists_without_default_slave?(*args, &block) }
      end
    end

    # in rails 4.1+, they create a join class that's used to pull in records for HABTM.
    # this simplifies the hell out of our existence, because all we have to do is inerit on-slave-by-default
    # down from the parent now.
    module Rails41HasAndBelongsToManyBuilderExtension
      def self.included(base)
        base.class_eval do
          alias_method :through_model_without_inherit_default_slave_from_lhs, :through_model
          alias_method :through_model, :through_model_with_inherit_default_slave_from_lhs
        end
      end

      def through_model_with_inherit_default_slave_from_lhs
        model = through_model_without_inherit_default_slave_from_lhs
        def model.on_slave_by_default?
          left_reflection.klass.on_slave_by_default?
        end

        # also transfer the sharded-ness of the left table to the join model
        model.not_sharded unless model.left_reflection.klass.is_sharded?
        model
      end
    end
  end
end
